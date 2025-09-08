`timescale 1ns/1ns

module activate_LED_tb;

    // Testbench signals
    reg clk, rst;
    reg LED_toggle;
    reg [3:0] rng_led, rng_led2;
    reg [9:0] hit_LEDs;
    wire [9:0] LEDR;

    // DUT instance
    activate_LED dut (
        .clk(clk),
        .rst(rst),
        .LED_toggle(LED_toggle),
        .rng_led(rng_led),
        .rng_led2(rng_led2),
        .hit_LEDs(hit_LEDs),
        .LEDR(LEDR)
    );

    // Clock generation (20ns period = 50 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    always @(LEDR) begin
    $display("Time %0t: LEDR = %b", $time, LEDR);
    end

    // Stimulus
    initial begin
        // Dump waveforms for GTKWave
        $dumpfile("activate_LED_tb.vcd");
        $dumpvars(0, activate_LED_tb);

        // Initialize signals
        rst = 1;
        LED_toggle = 0;
        rng_led = 0;
        rng_led2 = 0;
        hit_LEDs = 10'b0;

        // Hold reset for a bit
        #20;
        rst = 0;

        // First spawn: LEDs 3 and 7
        rng_led = 4'd3;
        rng_led2 = 4'd7;
        LED_toggle = 1;
        #10 LED_toggle = 0;
        #30;

        // Hit LED 3 (turn it off, 7 should remain)
        hit_LEDs = 10'b0000001000;  // one-hot for LED3
        #10 hit_LEDs = 10'b0;
        #30;

        // Spawn again: LEDs 1 and 9
        rng_led = 4'd1;
        rng_led2 = 4'd9;
        LED_toggle = 1;
        #10 LED_toggle = 0;
        #30;

        // Hit both LEDs (1 and 9), should clear them
        hit_LEDs = (10'b0000000010 | 10'b1000000000);
        #10 hit_LEDs = 10'b0;
        #30;

        // Another spawn with overlapping LED (LED7 reused)
        rng_led = 4'd7;
        rng_led2 = 4'd5;
        LED_toggle = 1;
        #10 LED_toggle = 0;
        #50;

        // End simulation
        $finish;
    end
endmodule