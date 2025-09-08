`timescale 1ns/1ps

module switch_detector_tb;

    // Testbench parameters
    parameter WIDTH = 8;           // Reduced width for easier testing
    parameter CLK_PERIOD = 20;     // 50MHz clock (20ns period)

    // Testbench signals
    reg clk;
    reg rst;
    reg [WIDTH-1:0] signal;
    wire [WIDTH-1:0] rise_detect;
    wire [WIDTH-1:0] fall_detect;
    wire [WIDTH-1:0] edge_detect;

    // Instantiate the Unit Under Test (UUT)
    switch_detector #(
        .WIDTH(WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .signal(signal),
        .rise_detect(rise_detect),
        .fall_detect(fall_detect),
        .edge_detect(edge_detect)
    );

    // Clock generation (50 MHz)
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test sequence
    initial begin
        $display("=== Switch Detector Test ===");
        $display("Testing %0d-bit wide switch detector", WIDTH);
        
        // Initialize inputs
        rst = 1;
        signal = 0;
        
        // Apply reset
        #(CLK_PERIOD * 3);
        rst = 0;
        #(CLK_PERIOD);
        
        $display("Time=%0t: Reset released, starting tests", $time);
        $display("Initial: signal=%b, rise=%b, fall=%b, edge=%b", 
                 signal, rise_detect, fall_detect, edge_detect);
        
        // Test 1: Single bit rising edge
        $display("\n--- Test 1: Single Bit Rising Edge ---");
        signal = 8'b00000001;
        #(CLK_PERIOD);
        $display("Time=%0t: signal=%b, rise=%b, fall=%b, edge=%b", 
                 $time, signal, rise_detect, fall_detect, edge_detect);
        
        // Test 2: Single bit falling edge
        $display("\n--- Test 2: Single Bit Falling Edge ---");
        signal = 8'b00000000;
        #(CLK_PERIOD);
        $display("Time=%0t: signal=%b, rise=%b, fall=%b, edge=%b", 
                 $time, signal, rise_detect, fall_detect, edge_detect);
        
        // Test 3: Multiple bits rising
        $display("\n--- Test 3: Multiple Bits Rising ---");
        signal = 8'b00001111;
        #(CLK_PERIOD);
        $display("Time=%0t: signal=%b, rise=%b, fall=%b, edge=%b", 
                 $time, signal, rise_detect, fall_detect, edge_detect);
        
        // Test 4: Multiple bits falling
        $display("\n--- Test 4: Multiple Bits Falling ---");
        signal = 8'b00000000;
        #(CLK_PERIOD);
        $display("Time=%0t: signal=%b, rise=%b, fall=%b, edge=%b", 
                 $time, signal, rise_detect, fall_detect, edge_detect);
        
        // Test 5: Mixed edges (some rising, some falling)
        $display("\n--- Test 5: Mixed Edges ---");
        signal = 8'b11110000;
        #(CLK_PERIOD);
        signal = 8'b00001111;
        #(CLK_PERIOD);
        $display("Time=%0t: signal=%b, rise=%b, fall=%b, edge=%b", 
                 $time, signal, rise_detect, fall_detect, edge_detect);
        
        // Test 6: Alternating pattern
        $display("\n--- Test 6: Alternating Pattern ---");
        signal = 8'b10101010;
        #(CLK_PERIOD);
        $display("Time=%0t: signal=%b, rise=%b, fall=%b, edge=%b", 
                 $time, signal, rise_detect, fall_detect, edge_detect);
        
        signal = 8'b01010101;
        #(CLK_PERIOD);
        $display("Time=%0t: signal=%b, rise=%b, fall=%b, edge=%b", 
                 $time, signal, rise_detect, fall_detect, edge_detect);
        
        // Test 7: No change (should produce no edges)
        $display("\n--- Test 7: No Change ---");
        signal = 8'b01010101;  // Same as previous
        #(CLK_PERIOD);
        $display("Time=%0t: signal=%b, rise=%b, fall=%b, edge=%b", 
                 $time, signal, rise_detect, fall_detect, edge_detect);
        
        // Test 8: All bits high to low
        $display("\n--- Test 8: All Bits High to Low ---");
        signal = 8'b11111111;
        #(CLK_PERIOD);
        signal = 8'b00000000;
        #(CLK_PERIOD);
        $display("Time=%0t: signal=%b, rise=%b, fall=%b, edge=%b", 
                 $time, signal, rise_detect, fall_detect, edge_detect);
        
        // Test 9: All bits low to high
        $display("\n--- Test 9: All Bits Low to High ---");
        signal = 8'b11111111;
        #(CLK_PERIOD);
        $display("Time=%0t: signal=%b, rise=%b, fall=%b, edge=%b", 
                 $time, signal, rise_detect, fall_detect, edge_detect);
        
        // Test 10: Reset during operation
        $display("\n--- Test 10: Reset During Operation ---");
        signal = 8'b10101010;
        #(CLK_PERIOD);
        rst = 1;
        #(CLK_PERIOD);
        $display("Time=%0t: Reset applied - rise=%b, fall=%b, edge=%b", 
                 $time, rise_detect, fall_detect, edge_detect);
        
        rst = 0;
        #(CLK_PERIOD);
        $display("Time=%0t: Reset released - rise=%b, fall=%b, edge=%b", 
                 $time, rise_detect, fall_detect, edge_detect);
        
        // Test 11: Rapid changes
        $display("\n--- Test 11: Rapid Changes ---");
        repeat(5) begin
            signal = $random;
            #(CLK_PERIOD);
            $display("Time=%0t: signal=%b, edges=%b", $time, signal, edge_detect);
        end
        
        // Final wait and finish
        #(CLK_PERIOD * 5);
        $display("\nSwitch detector test completed successfully!");
        $finish;
    end

    // Monitor for any edge detection
    always @(posedge clk) begin
        if (|rise_detect)
            $display("Time=%0t: *** RISING EDGE detected on bits: %b ***", $time, rise_detect);
        if (|fall_detect)
            $display("Time=%0t: *** FALLING EDGE detected on bits: %b ***", $time, fall_detect);
        if (|edge_detect)
            $display("Time=%0t: *** ANY EDGE detected on bits: %b ***", $time, edge_detect);
    end

    // Dump waveforms for viewing
    initial begin
        $dumpfile("switch_detector_test.vcd");
        $dumpvars(0, switch_detector_tb);
    end

endmodule
