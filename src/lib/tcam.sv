`include "include.svh"

// RAM-based multi-slice TCAM.
// Total key/data width = NUM_KEYRAM * DATA_WIDTH bits.
//
// Architecture: NUM_KEYRAM key RAMs, each keyed by a DATA_WIDTH-bit slice
// of the lookup data. Each RAM entry (MAX_ENTRY bits wide) is a bitmask
// indicating which TCAM entries match that slice value.
//
// INSERT: Scans all WORD_DEPTH addresses; issues RMW only where addr_match is
//         true for at least one RAM. Cycles = WORD_DEPTH + num_matched_addrs.
//         Worst case (all-wildcard): 2 * WORD_DEPTH cycles.
// DELETE (key/mask-based): Same scan; clears entry bits only at matching
//         addresses. Supply the original INSERT key/mask for minimal writes.
// DELETE (entry-based): Pass mask = 0 (all don't-care) to clear the entry from
//         every address. Always takes 2 * WORD_DEPTH cycles.
// LOOKUP: Reads all key RAMs in parallel and ANDs their outputs.
//         Result is valid 2 cycles after the lookup command.

module tcam #(
    parameter int DATA_WIDTH    = 4,
    parameter int WORD_DEPTH    = 2 ** DATA_WIDTH,   // entries per key RAM
    parameter int NUM_KEYRAM    = 4,
    parameter int MAX_ENTRY     = 8,
    // 1: output is one-hot of the highest-priority (lowest index) matching entry
    // 0: output is the full hit vector
    parameter int GEN_PRIO_RESP = 1
) (
    input  wire  clk,
    input  wire  resetn,

    // Handshaking: command is accepted when cmd_valid & cmd_ready
    input  wire  cmd_valid,
    output logic cmd_ready,

    // cmd: 2'b00=INSERT, 2'b01=DELETE, 2'b10=LOOKUP
    input  wire  [1:0]                       cmd,
    // key and mask for INSERT (NUM_KEYRAM * DATA_WIDTH bits total)
    // mask bit = 0 means don't-care
    input  wire  [NUM_KEYRAM*DATA_WIDTH-1:0] key,
    input  wire  [NUM_KEYRAM*DATA_WIDTH-1:0] mask,
    // entry select (one-hot) for INSERT / DELETE
    input  wire  [MAX_ENTRY-1:0]             entry_in,

    // Lookup data (NUM_KEYRAM * DATA_WIDTH bits)
    input  wire  [NUM_KEYRAM*DATA_WIDTH-1:0] data,
    // Lookup result: hit vector or one-hot priority result
    output logic [MAX_ENTRY-1:0]             entry_out,
    output logic                             entry_out_valid
);

    // ---------------------------------------------------------------
    // Parameters & local constants
    // ---------------------------------------------------------------
    localparam logic [1:0] CInsert = 2'b00;
    localparam logic [1:0] CDelete = 2'b01;
    localparam logic [1:0] CLookup = 2'b10;

    // ---------------------------------------------------------------
    // State machine
    // ---------------------------------------------------------------
    typedef enum logic [2:0] {
        S_INIT,           // clear all key RAMs after reset
        S_IDLE,
        S_LOOKUP_WAIT,    // wait 1 cycle for sdpram read result
        S_INS_DEL_SCAN,   // check addr_match; issue READ only if any RAM matches
        S_INS_DEL_WRITE   // write modified value back to matching RAMs
    } state_e;

    state_e state, state_next;

    // ---------------------------------------------------------------
    // Iteration counters
    // ---------------------------------------------------------------
    logic [DATA_WIDTH-1:0]  addr_cnt;

    wire last_addr = (addr_cnt == DATA_WIDTH'(WORD_DEPTH - 1));

    // ---------------------------------------------------------------
    // Latched command registers
    // ---------------------------------------------------------------
    logic [NUM_KEYRAM*DATA_WIDTH-1:0] key_r, mask_r, data_r;
    logic [MAX_ENTRY-1:0]             entry_r;
    logic [1:0]                       cmd_r;

    // ---------------------------------------------------------------
    // Key RAM signals
    // ---------------------------------------------------------------
    logic [DATA_WIDTH-1:0]  ram_addra [NUM_KEYRAM];
    logic [MAX_ENTRY-1:0]   ram_dina  [NUM_KEYRAM];
    logic                   ram_wea   [NUM_KEYRAM];
    logic                   ram_ena   [NUM_KEYRAM];
    logic [DATA_WIDTH-1:0]  ram_addrb [NUM_KEYRAM];
    logic                   ram_enb   [NUM_KEYRAM];
    logic [MAX_ENTRY-1:0]   ram_doutb [NUM_KEYRAM];

    // ---------------------------------------------------------------
    // Per-slice address match
    //   addr_cnt matches slice i if all care bits (mask=1) equal key bits
    // ---------------------------------------------------------------
    logic addr_match [NUM_KEYRAM];

    genvar g;
    generate
        for (g = 0; g < NUM_KEYRAM; g++) begin : gen_match
            wire [DATA_WIDTH-1:0] k_slice = key_r [g*DATA_WIDTH +: DATA_WIDTH];
            wire [DATA_WIDTH-1:0] m_slice = mask_r[g*DATA_WIDTH +: DATA_WIDTH];
            assign addr_match[g] = ((addr_cnt & m_slice) == (k_slice & m_slice));
        end
    endgenerate

    // True when at least one RAM needs RMW at the current addr_cnt
    logic any_match;
    always_comb begin
        any_match = 1'b0;
        for (int i = 0; i < NUM_KEYRAM; i++)
            any_match |= addr_match[i];
    end

    // ---------------------------------------------------------------
    // Key RAM instances
    //   DATA_WIDTH of sdpram = MAX_ENTRY  (stores hit bitmask)
    //   WORD_DEPTH of sdpram = DATA_WIDTH (address width per slice)
    // ---------------------------------------------------------------
    generate
        for (g = 0; g < NUM_KEYRAM; g++) begin : gen_keyram
            sdpram #(
                .DATA_WIDTH(MAX_ENTRY),
                .WORD_DEPTH(DATA_WIDTH)
            ) u_keyram (
                .clk    (clk),
                .resetn (resetn),
                .addra  (ram_addra[g]),
                .dina   (ram_dina[g]),
                .wea    (ram_wea[g]),
                .ena    (ram_ena[g]),
                .addrb  (ram_addrb[g]),
                .enb    (ram_enb[g]),
                .doutb  (ram_doutb[g])
            );
        end
    endgenerate

    // ---------------------------------------------------------------
    // State machine — next-state logic
    // ---------------------------------------------------------------
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) state <= S_INIT;
        else         state <= state_next;
    end

    always_comb begin
        state_next = state;
        case (state)
            S_INIT: begin
                if (last_addr) state_next = S_IDLE;
            end
            S_IDLE: begin
                if (cmd_valid) begin
                    case (cmd)
                        CLookup: state_next = S_LOOKUP_WAIT;
                        default: state_next = S_INS_DEL_SCAN;
                    endcase
                end
            end
            S_LOOKUP_WAIT: state_next = S_IDLE;
            S_INS_DEL_SCAN: begin
                if      (any_match)  state_next = S_INS_DEL_WRITE; // READ issued; proceed to WRITE
                else if (last_addr)  state_next = S_IDLE;           // no match at last addr; done
                // else: no match, not last; addr_cnt advances, stay in SCAN
            end
            S_INS_DEL_WRITE: begin
                if (last_addr) state_next = S_IDLE;
                else           state_next = S_INS_DEL_SCAN;
            end
            default: state_next = S_IDLE;
        endcase
    end

    // ---------------------------------------------------------------
    // Counter control
    // ---------------------------------------------------------------
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            addr_cnt <= '0;
        end else begin
            case (state)
                S_INIT: begin
                    addr_cnt <= last_addr ? '0 : addr_cnt + 1'b1;
                end
                S_IDLE: begin
                    if (cmd_valid && cmd != CLookup)
                        addr_cnt <= '0;
                end
                S_INS_DEL_SCAN: begin
                    // Advance only when skipping (no match); hold when issuing READ
                    if (!any_match)
                        addr_cnt <= last_addr ? '0 : addr_cnt + 1'b1;
                end
                S_INS_DEL_WRITE: begin
                    addr_cnt <= last_addr ? '0 : addr_cnt + 1'b1;
                end
                default: ;
            endcase
        end
    end

    // ---------------------------------------------------------------
    // Latch incoming command
    // ---------------------------------------------------------------
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            key_r   <= '0;
            mask_r  <= '0;
            data_r  <= '0;
            entry_r <= '0;
            cmd_r   <= '0;
        end else if (state == S_IDLE && cmd_valid) begin
            key_r   <= key;
            mask_r  <= mask;
            data_r  <= data;
            entry_r <= entry_in;
            cmd_r   <= cmd;
        end
    end

    // ---------------------------------------------------------------
    // Key RAM control
    // ---------------------------------------------------------------
    always_comb begin
        for (int i = 0; i < NUM_KEYRAM; i++) begin
            ram_addra[i] = '0;
            ram_dina[i]  = '0;
            ram_wea[i]   = 1'b0;
            ram_ena[i]   = 1'b0;
            ram_addrb[i] = '0;
            ram_enb[i]   = 1'b0;
        end

        case (state)
            // Write 0 to every address in every RAM to initialise
            S_INIT: begin
                for (int i = 0; i < NUM_KEYRAM; i++) begin
                    ram_ena[i]   = 1'b1;
                    ram_wea[i]   = 1'b1;
                    ram_addra[i] = addr_cnt;
                    ram_dina[i]  = '0;
                end
            end

            // Issue reads for all key RAMs in parallel using data slices
            S_IDLE: begin
                if (cmd_valid && cmd == CLookup) begin
                    for (int i = 0; i < NUM_KEYRAM; i++) begin
                        ram_enb[i]   = 1'b1;
                        ram_addrb[i] = data[i*DATA_WIDTH +: DATA_WIDTH];
                    end
                end
            end

            // Issue READ to all RAMs at addr_cnt — only when any RAM matches
            S_INS_DEL_SCAN: begin
                if (any_match) begin
                    for (int i = 0; i < NUM_KEYRAM; i++) begin
                        ram_enb[i]   = 1'b1;
                        ram_addrb[i] = addr_cnt;
                    end
                end
            end

            // RMW write phase: only update RAMs where addr_match[i] is true
            S_INS_DEL_WRITE: begin
                for (int i = 0; i < NUM_KEYRAM; i++) begin
                    if (addr_match[i]) begin
                        ram_ena[i]   = 1'b1;
                        ram_wea[i]   = 1'b1;
                        ram_addra[i] = addr_cnt;
                        ram_dina[i]  = (cmd_r == CInsert) ?
                                       (ram_doutb[i] | entry_r) :   // INSERT: OR in entry bit
                                       (ram_doutb[i] & ~entry_r);   // DELETE: AND out entry bit
                    end
                end
            end

            default: ;
        endcase
    end

    // ---------------------------------------------------------------
    // cmd_ready
    // ---------------------------------------------------------------
    assign cmd_ready = (state == S_IDLE);

    // ---------------------------------------------------------------
    // Lookup result: AND of all key RAM outputs
    // ---------------------------------------------------------------
    logic [MAX_ENTRY-1:0] hit_vec;
    always_comb begin
        hit_vec = '1;
        for (int i = 0; i < NUM_KEYRAM; i++)
            hit_vec &= ram_doutb[i];
    end

    // Priority encoder: lowest matching index wins (highest priority)
    // Iterates high→low so the lowest index overwrites all higher ones.
    logic [MAX_ENTRY-1:0] prio_vec;
    always_comb begin
        prio_vec = '0;
        for (int i = MAX_ENTRY-1; i >= 0; i--) begin
            if (hit_vec[i])
                prio_vec = MAX_ENTRY'(MAX_ENTRY'(1'b1) << i);
        end
    end

    // Register output; entry_out_valid pulses for one cycle after lookup
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            entry_out       <= '0;
            entry_out_valid <= 1'b0;
        end else begin
            entry_out_valid <= (state == S_LOOKUP_WAIT);
            if (state == S_LOOKUP_WAIT)
                entry_out <= GEN_PRIO_RESP ? prio_vec : hit_vec;
        end
    end

endmodule
