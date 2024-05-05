// `FF asynchronous active-low reset

`define FF_SYNC(clk, resetn, q, d, rstval)  \
  always_ff @(posedge clk) begin \
  q <= (!resetn) ? rstval : d; \
  end \

`define FF_ASYNC(clk, resetn, q, d, rstval)  \
  always_ff @(posedge clk or negedge resetn) begin \
    if(!resetn)   \
    q <= rstval;  \
    else          \
    q <=d;        \
  end

