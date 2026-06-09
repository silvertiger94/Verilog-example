# Verilog Example

SystemVerilog RTL 예제 모듈 모음과 UVM 기반 검증 환경을 제공하는 레퍼런스 프로젝트입니다.

## 프로젝트 구조

```
.
├── include/
│   ├── defines.svh          # 파라미터 / 매크로 정의
│   └── include.svh          # 공통 include (timescale, defines.svh)
├── src/
│   ├── lib/                 # RTL 라이브러리 모듈
│   └── tb/                  # UVM 테스트벤치
│       ├── base/            # UVM base 클래스 (pkg, env, test, vseqr, vseq)
│       ├── common/          # 공용 시퀀서 / 시퀀스 / 인터페이스 / tb_top
│       ├── entity/          # DUT별 시퀀스 및 UVM 에이전트
│       │   ├── fifo/        # FIFO 시퀀스
│       │   ├── mem/         # SPRAM / SDPRAM 시퀀스
│       │   └── sdpram/      # SDPRAM 전용 UVM 에이전트 (driver, monitor, scoreboard)
│       ├── intf/            # 인터페이스 정의
│       └── simple_tb/       # 단순 기능 검증용 standalone 테스트벤치
├── third_party/
│   └── uvm-verilator/       # UVM-Verilator (git submodule)
├── script/
│   └── filelist.f           # 파일리스트
└── Makefile                 # Verilator 빌드 스크립트
```

## RTL 모듈 목록

| 모듈 | 파일 | 설명 |
|------|------|------|
| `spram` | [src/lib/spram.sv](src/lib/spram.sv) | Single-Port RAM (active-low reset, 동기 읽기/쓰기) |
| `sdpram` | [src/lib/sdpram.sv](src/lib/sdpram.sv) | Simple Dual-Port RAM (포트 A: 쓰기, 포트 B: 읽기) |
| `fifo_reg` | [src/lib/fifo.sv](src/lib/fifo.sv) | 레지스터 기반 FIFO (full/empty 포함) |
| `async_fifo` | [src/lib/async_fifo.sv](src/lib/async_fifo.sv) | 비동기 클록 도메인 FIFO |
| `skid_buffer` | [src/lib/skid_buffer.sv](src/lib/skid_buffer.sv) | valid/ready 핸드셰이크 스키드 버퍼 |
| `synchronizer` | [src/lib/synchronizer.sv](src/lib/synchronizer.sv) | 2-플립플롭 CDC 동기화기 |
| `priority_arbiter` | [src/lib/priority_arbiter.sv](src/lib/priority_arbiter.sv) | LSB 우선 고정 우선순위 아비터 |
| `round_robin` | [src/lib/round_robin.sv](src/lib/round_robin.sv) | 라운드 로빈 아비터 |
| `multi_port_mux` | [src/lib/multi_port_mux.sv](src/lib/multi_port_mux.sv) | 파라미터화 멀티포트 MUX |
| `onehot_to_bin` | [src/lib/onehot_to_bin.sv](src/lib/onehot_to_bin.sv) | 원-핫 → 이진 인코더 |
| `tcam` | [src/lib/tcam.sv](src/lib/tcam.sv) | RAM 기반 다중 슬라이스 TCAM (INSERT / DELETE / LOOKUP) |

## 검증 환경

**Verilator** + [UVM-Verilator](https://github.com/chipsalliance/uvm-verilator) 기반 테스트벤치입니다.  
UVM을 사용하지 않는 standalone 테스트벤치(`simple_tb/`)도 함께 제공됩니다.

### UVM 테스트벤치 구조

```
src/tb/
├── base/
│   ├── base_pkg.sv          # 패키지 (uvm_pkg, 공용 클래스 import)
│   ├── base_env.sv          # 최상위 UVM env
│   ├── base_test.sv         # 기본 test (run_test 진입점)
│   ├── base_vseqr.sv        # 가상 시퀀서 (clock_reset_vif, generic_dut_seqr 보유)
│   └── base_vseq.sv         # 가상 시퀀스 (clock/reset 제어, DUT 시퀀스 실행)
├── common/
│   ├── generic_dut_seqr.sv  # DUT 전용 시퀀서 (clock_reset_vif + dut_vif 보유)
│   ├── generic_dut_base_seq.sv  # DUT 시퀀스 베이스 (wait_for_clock 등 헬퍼)
│   ├── stream_seq.sv        # 스트림 인터페이스 시퀀스
│   └── tb_top.sv            # 최상위 테스트벤치 모듈 (DUT 연결, config_db 설정)
├── entity/
│   ├── mem/mem_seq.sv       # SPRAM / SDPRAM 읽기/쓰기 시퀀스
│   ├── fifo/fifo_seq.sv     # FIFO push/pop 시퀀스
│   └── sdpram/              # SDPRAM 전용 UVM 에이전트
│       ├── sdpram_pkg.sv
│       ├── sdpram_if.sv
│       ├── sdpram_seq_item.sv
│       ├── sdpram_base_seq.sv
│       ├── sdpram_driver.sv
│       ├── sdpram_monitor.sv
│       ├── sdpram_scoreboard.sv
│       ├── sdpram_agent.sv
│       └── sdpram_env.sv
└── intf/
    ├── clock_reset_if.sv    # 클록 / 리셋 인터페이스
    └── generic_dut_if.sv    # 범용 DUT 인터페이스 (mem / fifo / stream 신호 통합)
```

현재 `tb_top`에는 `sdpram` DUT가 연결되어 있습니다.

## 빌드 및 시뮬레이션

### 사전 요구사항

- [Verilator](https://verilator.org) (PATH에 등록)
- [UVM-Verilator](https://github.com/chipsalliance/uvm-verilator): git submodule로 포함 (`make init`으로 자동 설치)
- GTKWave (파형 확인 시)

### 처음 설정

```bash
git clone https://github.com/silvertiger94/Verilog-example.git
cd Verilog-example
make init    # UVM-Verilator submodule 초기화
```

### 실행 방법

```bash
# 기본 실행 (verilate → run → coverage → 파형 오픈)
make

# 빌드 + 실행만 (파형 오픈 없음)
make build

# 단계별 실행
make verilate    # Verilator 컴파일
make run         # 시뮬레이션 실행
make cov         # 커버리지 리포트 생성
make wave        # GTKWave로 파형 확인

# 출력 디렉토리 정리
make clean       # sim/verilator/tb_top_* 삭제
make cleanall    # sim/verilator/ 전체 삭제

# 기타
make lint        # lint 검사
make show-config # Verilator 버전 및 설정 확인
```

### 시뮬레이션 출력

실행 결과는 타임스탬프 기반 디렉토리에 저장됩니다.

```
sim/verilator/tb_top_<YYYYMMDD_HHMMSS>/
├── obj_dir/             # Verilator 생성 파일 및 바이너리
└── logs/
    ├── sim.log          # 시뮬레이션 로그
    ├── vlt_dump.vcd     # 파형 덤프
    ├── coverage.info    # LCOV 커버리지 정보
    └── annotated/       # 소스 레벨 커버리지 주석
```

## 주요 파라미터

### SDPRAM / SPRAM

| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| `DATA_WIDTH` | 32 | 데이터 비트 폭 |
| `WORD_DEPTH` | 2 | 주소 비트 폭 (메모리 깊이 = 2^WORD_DEPTH) |

### TCAM

| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| `DATA_WIDTH` | 4 | 슬라이스당 키 비트 폭 |
| `NUM_KEYRAM` | 4 | 키 RAM 슬라이스 수 (총 키 폭 = NUM_KEYRAM × DATA_WIDTH) |
| `MAX_ENTRY` | 8 | TCAM 엔트리 수 |
| `GEN_PRIO_RESP` | 1 | 1: 최고 우선순위 원-핫 출력, 0: 전체 히트 벡터 출력 |
