`timescale 1ns/1ps

// ============================================================================
// Verilog Practical Starter
// ----------------------------------------------------------------------------
// 목적:
// 1) Verilog를 처음 다룰 때 실무에서 가장 자주 보는 구조를 한 파일에 모아둠
// 2) "문법"보다 "어떻게 설계해야 안전한지"에 초점을 맞춤
// 3) 각 예제는 바로 읽고 따라갈 수 있도록 주석을 자세히 작성함
//
// 이 파일에서 익혀야 할 핵심:
// - 조합논리와 순차논리를 분리하는 습관
// - blocking(=) / non-blocking(<=) 차이
// - latch가 왜 생기는지, 어떻게 피하는지
// - reset, enable, state machine 기본 구조
// - testbench로 최소한의 검증을 하는 방법
// - reg, wire가 무엇을 뜻하는지 감을 잡는 것
//
// 실무 팁:
// - FPGA/ASIC 팀마다 코딩 스타일은 조금씩 다르지만, 큰 원칙은 거의 같다.
// - "합성 가능한 코드인지", "타이밍이 안전한지", "유지보수 가능한지"가 중요하다.
//
// 참고:
// - Verilog의 reg는 "무조건 플립플롭"이라는 뜻이 아니다.
// - procedural block(always/initial) 안에서 값을 할당받는 변수 타입이라고 이해하는 편이 좋다.
// - wire는 assign 등으로 연결되는 신호선에 가깝다.
// ============================================================================


// ============================================================================
// 1. 조합논리 예제: 간단한 ALU
// ----------------------------------------------------------------------------
// 조합논리는 "현재 입력이 바뀌면 출력이 바로 바뀌는" 논리다.
// 클럭이 없다.
//
// 실무 포인트:
// - always @(*) 를 사용해서 sensitivity list 누락을 막는다.
// - 모든 출력에 기본값(default)을 주거나, 모든 case를 빠짐없이 채운다.
// - 그렇지 않으면 의도치 않은 latch가 생길 수 있다.
// ============================================================================
module simple_alu (
    input      [7:0] a,
    input      [7:0] b,
    input      [2:0] op,
    output reg [7:0] y,
    output reg       carry
);
    always @(*) begin
        // 기본값을 먼저 줘야 예외 경로에서도 출력이 정해진다.
        // 이 습관이 latch를 막는 데 매우 중요하다.
        y     = 8'd0;
        carry = 1'b0;

        case (op)
            3'b000: begin
                {carry, y} = a + b;
            end

            3'b001: begin
                {carry, y} = a - b;
            end

            3'b010: begin
                y = a & b;
            end

            3'b011: begin
                y = a | b;
            end

            3'b100: begin
                y = a ^ b;
            end

            3'b101: begin
                y = b << 1;
            end

            3'b110: begin
                y = b >> 1;
            end

            default: begin
                // default는 꼭 넣는 편이 안전하다.
                // 나중에 op가 X/Z가 섞이거나 예외값이 와도 출력이 정의된다.
                y     = 8'd0;
                carry = 1'b0;
            end
        endcase
    end
endmodule


// ============================================================================
// 2. 순차논리 예제: enable이 있는 카운터
// ----------------------------------------------------------------------------
// 순차논리는 클럭 edge에서 값이 바뀐다.
// 보통 always @(posedge clk) 또는 always @(posedge clk or negedge rst_n) 형태를 쓴다.
//
// 실무 포인트:
// - 순차논리에서는 non-blocking assignment(<=)를 사용한다.
// - reset 동작을 코드에서 명확히 보이게 만든다.
// - 카운터 폭(width)은 parameter로 빼두면 재사용성이 좋아진다.
// ============================================================================
module counter_with_enable #(
    parameter WIDTH = 8
) (
    input                  clk,
    input                  rst_n,   // active-low reset
    input                  en,
    output reg [WIDTH-1:0] count
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= {WIDTH{1'b0}};
        end else if (en) begin
            count <= count + 1'b1;
        end else begin
            // 순차논리에서는 값을 유지하고 싶다면 명시하지 않아도 된다.
            // 다만 의도를 분명히 보여주고 싶으면 아래처럼 쓸 수 있다.
            count <= count;
        end
    end
endmodule


// ============================================================================
// 3. 외부 비동기 입력 처리 예제: 버튼/신호 동기화 + 상승엣지 검출
// ----------------------------------------------------------------------------
// 현업에서 아주 자주 실수하는 부분이 "비동기 입력" 처리다.
// 예: 버튼 입력, 다른 클럭 도메인에서 넘어온 신호, 외부 핀 입력
//
// 문제:
// - 이런 신호를 바로 내부 로직에서 쓰면 metastability(메타안정성) 문제가 생길 수 있다.
//
// 기본 대응:
// - 두 단계 플립플롭으로 동기화한다.
// - 그 뒤 이전 값과 현재 값을 비교해서 edge를 검출한다.
// ============================================================================
module sync_and_rise_detect (
    input  clk,
    input  rst_n,
    input  async_in,
    output pulse
);
    reg sync_ff1;
    reg sync_ff2;
    reg sync_ff2_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1   <= 1'b0;
            sync_ff2   <= 1'b0;
            sync_ff2_d <= 1'b0;
        end else begin
            // 2-stage synchronizer
            sync_ff1   <= async_in;
            sync_ff2   <= sync_ff1;

            // 이전 cycle 값을 저장해서 edge 검출에 사용
            sync_ff2_d <= sync_ff2;
        end
    end

    // 현재 값이 1이고, 이전 값이 0이면 상승엣지로 판단
    assign pulse = sync_ff2 & ~sync_ff2_d;
endmodule


// ============================================================================
// 4. FSM(Finite State Machine) 예제: 요청을 받아 작업 후 done 출력
// ----------------------------------------------------------------------------
// FSM은 "상태(state)"를 기반으로 동작하는 로직이다.
//
// 실무에서 권장하는 기본 구조:
// - state register: 현재 상태 저장 (순차논리)
// - next-state logic: 다음 상태 계산 (조합논리)
// - output logic: 출력 계산 (조합논리 or 순차논리)
//
// 이 구조로 나누면 디버깅과 유지보수가 쉽다.
// ============================================================================
module simple_fsm (
    input  clk,
    input  rst_n,
    input  start,
    input  work_done,
    output reg busy,
    output reg done
);
    localparam S_IDLE = 2'b00;
    localparam S_RUN  = 2'b01;
    localparam S_DONE = 2'b10;

    reg [1:0] state;
    reg [1:0] next_state;

    // 현재 상태 저장
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 다음 상태 결정
    always @(*) begin
        // 기본값을 현재 상태로 두면 case에서 일부 분기를 빼먹어도 비교적 안전하다.
        next_state = state;

        case (state)
            S_IDLE: begin
                if (start) begin
                    next_state = S_RUN;
                end
            end

            S_RUN: begin
                if (work_done) begin
                    next_state = S_DONE;
                end
            end

            S_DONE: begin
                // done 상태를 1 cycle만 만들고 바로 IDLE로 돌아감
                next_state = S_IDLE;
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // 출력 로직
    always @(*) begin
        busy = 1'b0;
        done = 1'b0;

        case (state)
            S_IDLE: begin
                busy = 1'b0;
                done = 1'b0;
            end

            S_RUN: begin
                busy = 1'b1;
                done = 1'b0;
            end

            S_DONE: begin
                busy = 1'b0;
                done = 1'b1;
            end

            default: begin
                busy = 1'b0;
                done = 1'b0;
            end
        endcase
    end
endmodule


// ============================================================================
// 5. 실무에서 특히 조심할 것들
// ----------------------------------------------------------------------------
// 아래 bad example은 "왜 위험한지"를 보여주기 위한 설명용 모듈이다.
// 실제 코드베이스에서는 이런 스타일을 피하는 것이 좋다.
// ============================================================================
module bad_example_latch (
    input      sel,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] y
);
    always @(*) begin
        // 이 코드는 sel이 1일 때만 y를 할당한다.
        // sel이 0일 때 y가 어떻게 될지 정의하지 않았다.
        // 그러면 synthesis tool은 "이전 값을 기억해야 하네?"라고 보고
        // latch를 만들 수 있다.
        if (sel) begin
            y = a + b;
        end
    end
endmodule


// latch를 피한 버전
module good_example_no_latch (
    input       sel,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] y
);
    always @(*) begin
        // 기본값을 먼저 준다.
        y = 8'd0;

        if (sel) begin
            y = a + b;
        end
    end
endmodule


// ============================================================================
// 6. Blocking vs Non-Blocking 요약
// ----------------------------------------------------------------------------
// blocking (=):
// - 한 줄씩 즉시 실행되는 것처럼 보인다.
// - 조합논리 always @(*)에서 주로 사용
//
// non-blocking (<=):
// - 같은 clock edge에서 "동시에 업데이트"되는 모델
// - 순차논리 always @(posedge clk)에서 사용
//
// 실무 규칙:
// - 조합논리: 보통 =
// - 순차논리: 보통 <=
//
// 이 규칙을 섞어 쓰면 시뮬레이션과 합성 결과를 이해하기 어려워진다.
// ============================================================================
module blocking_vs_nonblocking (
    input  clk,
    input  rst_n,
    input  d,
    output reg q1,
    output reg q2
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q1 <= 1'b0;
            q2 <= 1'b0;
        end else begin
            // q1은 현재 d를 받고,
            // q2는 "이전 cycle의 q1"을 받는다.
            // 즉, 2-stage register처럼 동작한다.
            q1 <= d;
            q2 <= q1;
        end
    end
endmodule


// ============================================================================
// 7. 테스트벤치 예제
// ----------------------------------------------------------------------------
// 테스트벤치는 합성 대상이 아니다.
// 시뮬레이션에서 DUT(Device Under Test)를 검증하기 위한 코드다.
//
// 실무 포인트:
// - clock 생성
// - reset 인가
// - 입력 시나리오 제공
// - $display / waveform으로 확인
//
// 처음에는 "테스트벤치를 조금이라도 쓰는 습관"이 중요하다.
// ============================================================================
module tb_verilog_practical_starter;
    reg        clk;
    reg        rst_n;
    reg        en;
    reg  [7:0] a;
    reg  [7:0] b;
    reg  [2:0] op;
    reg        start;
    reg        work_done;
    reg        async_in;

    wire [7:0] alu_y;
    wire       alu_carry;
    wire [7:0] count;
    wire       pulse;
    wire       busy;
    wire       done;

    simple_alu u_alu (
        .a(a),
        .b(b),
        .op(op),
        .y(alu_y),
        .carry(alu_carry)
    );

    counter_with_enable #(
        .WIDTH(8)
    ) u_counter (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .count(count)
    );

    sync_and_rise_detect u_sync (
        .clk(clk),
        .rst_n(rst_n),
        .async_in(async_in),
        .pulse(pulse)
    );

    simple_fsm u_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .work_done(work_done),
        .busy(busy),
        .done(done)
    );

    // VCD(Value Change Dump) 파일 생성 설정
    // 이 파일을 GTKWave 같은 파형 뷰어로 열면 시간에 따라 신호가 어떻게 변하는지 볼 수 있다.
    initial begin
        $dumpfile("verilog_practical_starter.vcd");
        $dumpvars(0, tb_verilog_practical_starter);
    end

    // 100MHz clock라고 가정하면 주기는 10ns
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        // 초기값 설정
        rst_n     = 1'b0;
        en        = 1'b0;
        a         = 8'd0;
        b         = 8'd0;
        op        = 3'b000;
        start     = 1'b0;
        work_done = 1'b0;
        async_in  = 1'b0;

        // reset 유지
        #20;
        rst_n = 1'b1;

        // ALU 테스트
        a  = 8'd10;
        b  = 8'd3;
        op = 3'b000;  // add
        #10;
        $display("[ALU] add result=%0d carry=%0d", alu_y, alu_carry);

        op = 3'b001;  // sub
        #10;
        $display("[ALU] sub result=%0d carry=%0d", alu_y, alu_carry);

        op = 3'b100;  // xor
        #10;
        $display("[ALU] xor result=%0d", alu_y);

        // counter 테스트
        en = 1'b1;
        #50;
        en = 1'b0;
        $display("[COUNTER] count=%0d", count);

        // 비동기 입력 pulse 테스트
        #7  async_in = 1'b1;  // 클럭에 딱 맞지 않게 변화를 줘서 비동기 느낌을 냄
        #11 async_in = 1'b0;
        #30;

        // FSM 테스트
        start = 1'b1;
        #10;
        start = 1'b0;
        #20;
        work_done = 1'b1;
        #10;
        work_done = 1'b0;
        #20;
        $display("[FSM] busy=%0d done=%0d", busy, done);

        #20;
        $finish;
    end

    // 짧은 pulse 신호는 "나중에 한 번 출력"하면 이미 0으로 내려간 뒤일 수 있다.
    // 그래서 이벤트가 발생하는 순간을 잡아서 확인하는 습관이 중요하다.
    always @(posedge pulse) begin
        $display("[SYNC] rise pulse detected at time=%0t", $time);
    end

    always @(posedge clk) begin
        if (done) begin
            $display("[FSM] done pulse observed at time=%0t", $time);
        end
    end
endmodule


// ============================================================================
// 마지막 정리
// ----------------------------------------------------------------------------
// 처음 Verilog를 배울 때 가장 중요한 체크리스트:
//
// 1) 이 always block은 조합논리인가, 순차논리인가?
// 2) 조합논리라면 모든 출력이 항상 할당되는가?
// 3) 순차논리라면 <= 를 쓰고 있는가?
// 4) reset 동작이 명확한가?
// 5) 외부 입력/다른 클럭 도메인 신호를 바로 쓰고 있지 않은가?
// 6) testbench로 최소한의 동작 확인을 했는가?
//
// 여기까지 익히면 "문법을 아는 수준"에서 "실무 코드를 읽을 수 있는 수준"으로 넘어가기 쉽다.
// ============================================================================
