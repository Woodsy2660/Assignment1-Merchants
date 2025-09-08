`timescale 1ns/1ps

module switch_debounce_tb;

    // Testbench parameters
    parameter DELAY_COUNTS = 100;  // Reduced for faster simulation (2μs at 50MHz)
    parameter CLK_PERIOD = 20;     // 50MHz clock (20ns period)

    // Testbench signals
    reg clk;
    reg switch_input;
    wire switch_state;
    wire switch_pressed;
    wire switch_released;

    // Instantiate the Unit Under Test (UUT)
    switch_debounce #(
        .DELAY_COUNTS(DELAY_COUNTS)
    ) uut (
        .clk(clk),
        .switch_input(switch_input),
        .switch_state(switch_state),
        .switch_pressed(switch_pressed),
        .switch_released(switch_released)
    );

    // Clock generation (50 MHz)
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test sequence
    initial begin
        $display("=== Switch Debounce Test ===");
        
        // Initialize inputs
        switch_input = 0;
        
        // Wait for initial settling
        #(CLK_PERIOD * 10);
        $display("Time=%0t: Initial state - switch_input=%b, switch_state=%b", 
                 $time, switch_input, switch_state);
        
        // Test 1: Clean switch press (no bouncing)
        $display("\n--- Test 1: Clean Switch Press ---");
        switch_input = 1;
        #(CLK_PERIOD * 5);  // Wait a few clocks
        $display("Time=%0t: Switch pressed, waiting for debounce...", $time);
        
        // Wait for debounce delay
        #(CLK_PERIOD * DELAY_COUNTS * 2);
        $display("Time=%0t: After debounce - switch_state=%b, switch_pressed=%b", 
                 $time, switch_state, switch_pressed);
        
        // Test 2: Clean switch release
        $display("\n--- Test 2: Clean Switch Release ---");
        switch_input = 0;
        #(CLK_PERIOD * 5);
        $display("Time=%0t: Switch released, waiting for debounce...", $time);
        
        // Wait for debounce delay
        #(CLK_PERIOD * DELAY_COUNTS * 2);
        $display("Time=%0t: After debounce - switch_state=%b, switch_released=%b", 
                 $time, switch_state, switch_released);
        
        // Test 3: Bouncing switch press
        $display("\n--- Test 3: Bouncing Switch Press ---");
        repeat(10) begin
            switch_input = ~switch_input;
            #(CLK_PERIOD * 2);  // Short bounces
        end
        switch_input = 1;  // Final stable state
        $display("Time=%0t: Bouncing finished, switch should stabilize high", $time);
        
        // Wait for debounce
        #(CLK_PERIOD * DELAY_COUNTS * 2);
        $display("Time=%0t: After bounce debounce - switch_state=%b", $time, switch_state);
        
        // Test 4: Bouncing switch release
        $display("\n--- Test 4: Bouncing Switch Release ---");
        repeat(8) begin
            switch_input = ~switch_input;
            #(CLK_PERIOD * 3);  // Short bounces
        end
        switch_input = 0;  // Final stable state
        $display("Time=%0t: Bouncing finished, switch should stabilize low", $time);
        
        // Wait for debounce
        #(CLK_PERIOD * DELAY_COUNTS * 2);
        $display("Time=%0t: After bounce debounce - switch_state=%b", $time, switch_state);
        
        // Test 5: Very short glitches (should be ignored)
        $display("\n--- Test 5: Short Glitches (Should be Ignored) ---");
        switch_input = 1;
        #(CLK_PERIOD * 10);  // Short pulse
        switch_input = 0;
        #(CLK_PERIOD * 50);  // Wait less than debounce time
        $display("Time=%0t: Short glitch applied - switch_state should remain=%b", 
                 $time, switch_state);
        
        // Test 6: Edge detection verification
        $display("\n--- Test 6: Edge Detection Verification ---");
        switch_input = 1;
        #(CLK_PERIOD * DELAY_COUNTS * 2);
        $display("Time=%0t: Rising edge - switch_pressed should pulse", $time);
        
        switch_input = 0;
        #(CLK_PERIOD * DELAY_COUNTS * 2);
        $display("Time=%0t: Falling edge - switch_released should pulse", $time);
        
        // Final wait and finish
        #(CLK_PERIOD * 20);
        $display("\nSwitch debounce test completed successfully!");
        $finish;
    end

    // Monitor for edge detection pulses
    always @(posedge clk) begin
        if (switch_pressed)
            $display("Time=%0t: *** SWITCH_PRESSED pulse detected ***", $time);
        if (switch_released)
            $display("Time=%0t: *** SWITCH_RELEASED pulse detected ***", $time);
    end

    // Monitor switch state changes
    always @(switch_state) begin
        $display("Time=%0t: Switch state changed to %b", $time, switch_state);
    end

    // Dump waveforms for viewing
    initial begin
        $dumpfile("switch_debounce_test.vcd");
        $dumpvars(0, switch_debounce_tb);
    end

endmodule
