`timescale 1ns/1ns

module level_select_tb;

    // DUT inputs
    reg clk;
    reg rst;
    reg [3:1] keys;   // active-low buttons

    // DUT outputs
    wire [1:0] current_level;
    wire       level_reset;

    // Instantiate DUT with reduced debounce delay for simulation
    level_select #(.DELAY_COUNTS(3)) dut (
        .clk(clk),
        .rst(rst),
        .keys(keys),
        .current_level(current_level),
        .level_reset(level_reset)
        
    );

    // Clock generation (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        $dumpfile("level_select_tb.vcd");
        $dumpvars(0, level_select_tb);

        // Init
        rst = 1;
        keys = 3'b111; // all released (active-low)
        #20 rst = 0;

        // Press KEY1 (Level 1)
        #20 keys[1] = 0;  // press
        #200 keys[1] = 1; // release

        // Press KEY2 (Level 2)
        #200 keys[2] = 0;
        #200 keys[2] = 1;

        // Press KEY3 (Level 3)
        #200 keys[3] = 0;
        #200 keys[3] = 1;

        // Back to KEY1
        #200 keys[1] = 0;
        #200 keys[1] = 1;

        #500 $finish;
    end

    // Monitor
    always @(posedge clk) begin
        if (level_reset)
            $display("t=%0t ns: Level changed to %0d", $time, current_level);
    end

endmodule