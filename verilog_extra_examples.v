`timescale 1ns/1ps

// ============================================================================
// Verilog Extra Examples
// ----------------------------------------------------------------------------
// 목적:
// - starter 예제를 본 뒤 바로 이어서 볼 수 있는 실무형 패턴 모음
// - "한 번 더 생각해야 하는" 제어 로직을 짧고 읽기 쉽게 제공
//
// 포함된 패턴:
// 1) saturating counter
// 2) pulse stretcher
// 3) button pulse -> LED toggle
// ============================================================================


// ============================================================================
// 1. Saturating Counter
// ----------------------------------------------------------------------------
// 일반 카운터는 최대값 다음에 overflow로 다시 0이 될 수 있다.
// 하지만 실무에서는 "최대값에서 멈추는" 포화 카운터가 더 필요한 경우가 많다.
// 예: timeout 누적, error count, 안정화 대기 cycle count
// ============================================================================
module saturating_counter #(
    parameter WIDTH = 8
) (
    input                  clk,
    input                  rst_n,
    input                  en,
    output reg [WIDTH-1:0] count,
    output                 at_max
);
    localparam [WIDTH-1:0] MAX_VALUE = {WIDTH{1'b1}};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= {WIDTH{1'b0}};
        end else if (en) begin
            if (count != MAX_VALUE) begin
                count <= count + 1'b1;
            end
        end
    end

    assign at_max = (count == MAX_VALUE);
endmodule


// ============================================================================
// 2. Pulse Stretcher
// ----------------------------------------------------------------------------
// 1-cycle pulse는 다음 블록이 놓치기 쉽다.
// 그래서 실무에서는 pulse를 몇 cycle 더 유지시키는 회로를 자주 쓴다.
//
// 알고리즘:
// - in_pulse가 들어오면 내부 카운터를 PRESET 값으로 로드
// - 카운터가 0이 아닐 동안 out_level=1 유지
// - 매 cycle마다 1씩 감소
// ============================================================================
module pulse_stretcher #(
    parameter STRETCH_CYCLES = 4
) (
    input  clk,
    input  rst_n,
    input  in_pulse,
    output out_level
);
    reg [31:0] hold_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hold_count <= 32'd0;
        end else if (in_pulse) begin
            hold_count <= STRETCH_CYCLES[31:0];
        end else if (hold_count != 32'd0) begin
            hold_count <= hold_count - 1'b1;
        end
    end

    assign out_level = (hold_count != 32'd0);
endmodule


// ============================================================================
// 3. Button Pulse To LED Toggle
// ----------------------------------------------------------------------------
// 버튼이 눌릴 때마다 LED 상태를 토글하는 패턴이다.
//
// 실무 핵심:
// - 버튼은 비동기 입력으로 들어온다고 가정
// - 내부에서는 동기화된 1-cycle pulse로 바꿔서 사용
// - 상태를 바꾸는 것은 순차논리에서 처리
// ============================================================================
module button_pulse_toggle (
    input  clk,
    input  rst_n,
    input  button_async,
    output reg led
);
    reg sync_ff1;
    reg sync_ff2;
    reg sync_ff2_d;

    wire button_pulse;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1   <= 1'b0;
            sync_ff2   <= 1'b0;
            sync_ff2_d <= 1'b0;
        end else begin
            sync_ff1   <= button_async;
            sync_ff2   <= sync_ff1;
            sync_ff2_d <= sync_ff2;
        end
    end

    assign button_pulse = sync_ff2 & ~sync_ff2_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led <= 1'b0;
        end else if (button_pulse) begin
            led <= ~led;
        end
    end
endmodule


// ============================================================================
// 4. Mini Testbench
// ----------------------------------------------------------------------------
// 추가 예제 중 pulse stretcher와 button toggle 동작을 짧게 확인한다.
// ============================================================================
module tb_verilog_extra_examples;
    reg clk;
    reg rst_n;
    reg en;
    reg in_pulse;
    reg button_async;

    wire [3:0] sat_count;
    wire       at_max;
    wire       stretched;
    wire       led;

    saturating_counter #(
        .WIDTH(4)
    ) u_sat_counter (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .count(sat_count),
        .at_max(at_max)
    );

    pulse_stretcher #(
        .STRETCH_CYCLES(3)
    ) u_pulse_stretcher (
        .clk(clk),
        .rst_n(rst_n),
        .in_pulse(in_pulse),
        .out_level(stretched)
    );

    button_pulse_toggle u_button_toggle (
        .clk(clk),
        .rst_n(rst_n),
        .button_async(button_async),
        .led(led)
    );

    initial begin
        $dumpfile("verilog_extra_examples.vcd");
        $dumpvars(0, tb_verilog_extra_examples);
    end

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n        = 1'b0;
        en           = 1'b0;
        in_pulse     = 1'b0;
        button_async = 1'b0;

        #20;
        rst_n = 1'b1;

        // 포화 카운터 테스트
        en = 1'b1;
        #200;
        en = 1'b0;
        $display("[SAT] count=%0d at_max=%0d", sat_count, at_max);

        // pulse stretch 테스트
        #10;
        in_pulse = 1'b1;
        #10;
        in_pulse = 1'b0;

        // 버튼 토글 테스트
        #17 button_async = 1'b1;
        #14 button_async = 1'b0;
        #40 button_async = 1'b1;
        #12 button_async = 1'b0;

        #80;
        $display("[TOGGLE] led=%0d", led);
        $finish;
    end

    always @(posedge clk) begin
        if (stretched) begin
            $display("[STRETCH] out_level=1 at time=%0t", $time);
        end
    end
endmodule
