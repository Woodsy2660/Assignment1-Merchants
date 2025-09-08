`timescale 1ns/1ps
`default_nettype none

module mole_detector_tb;

  // DUT I/O
  logic clk, rst, LED_toggle;
  logic [9:0] active_onehot, btn_edge;

  /* verilator lint_off UNUSEDSIGNAL */
  logic armed, hit_pulse, double_hit_pulse, miss_pulse; // observed in waves
  /* verilator lint_on UNUSEDSIGNAL */
  logic [9:0] moles_hit;

  // 1 ns clock so the whole run is ~0.12 µs
  initial clk = 1'b0;
  always #0.5 clk = ~clk;   // 1 ns period

  // DUT
  mole_detector #(.N_MOLES(10)) dut (
    .clk(clk), .rst(rst), .LED_toggle(LED_toggle),
    .active_onehot(active_onehot), .btn_edge(btn_edge),
    .armed(armed), .hit_pulse(hit_pulse),
    .double_hit_pulse(double_hit_pulse), .miss_pulse(miss_pulse),
    .moles_hit(moles_hit)
  );

  // Waves (FST = small/fast)
  initial begin
    $dumpfile("wave.fst");
    $dumpvars(0, mole_detector_tb_1);
    $dumpvars(0, dut);
  end

  // Reset
  initial begin
    rst=1; LED_toggle=0; active_onehot='0; btn_edge='0;
    repeat (2) @(posedge clk);
    rst=0;
  end

  // Helper tasks (2-cycle pulses for visibility)
  task automatic set_active(input logic [9:0] bits);
    active_onehot = bits; @(posedge clk);
  endtask

  task automatic hit2(input logic [9:0] bits);
    btn_edge = bits; @(posedge clk); @(posedge clk);
    btn_edge = '0;  @(posedge clk);
  endtask

  task automatic led_timeout2;
    LED_toggle = 1; @(posedge clk); @(posedge clk);
    LED_toggle = 0; @(posedge clk);
  endtask

  // Compressed scenarios back-to-back
  initial begin
    @(negedge rst);

    // T1: Single hit (mole 0) -> hit_pulse=1, clean DONE
    set_active(10'b0000000001);
    hit2(10'b0000000001);

    // T2: Partial hit then timeout via LED_toggle -> miss_pulse=1 in DONE
    set_active(10'b0000000011);
    hit2(10'b0000000001);   // only mole0 hit, mole1 remains
    led_timeout2();

    // T3: True double hit same cycle (moles 2 & 3) -> double_hit_pulse=1 in DONE
    set_active(10'b0000001100);
    hit2(10'b0000001100);

    // T4: Spurious button with no active moles -> no pulses
    set_active('0);
    hit2(10'b0000000001);

    // T5: Mole appears then disappears (active_onehot->0) -> miss path via timeout condition
    set_active(10'b0000010000);
    set_active('0);

    // Tail & finish
    repeat (6) @(posedge clk);
    $finish;
  end

endmodule

`default_nettype wire
