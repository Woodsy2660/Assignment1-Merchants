`timescale 1ns/1ps

module score_updater_tb;

    // Testbench signals
    reg clk;
    reg rst;
    reg hit_pulse;
    reg miss_pulse;
    reg double_hit_pulse;
    wire [15:0] score;

    // Instantiate DUT
    score_updater uut (
        .clk(clk),
        .rst(rst),
        .hit_pulse(hit_pulse),
        .miss_pulse(miss_pulse),
        .double_hit_pulse(double_hit_pulse),
        .score(score)
    );

    // Clock generation: 10ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        // Initialize
        rst = 1;
        hit_pulse = 0;
        miss_pulse = 0;
        double_hit_pulse = 0;

        // Reset sequence
        #12 rst = 0;

        // 5 normal hits
        #10 hit_pulse = 1; #10 hit_pulse = 0;
        #20 hit_pulse = 1; #10 hit_pulse = 0;
        #20 hit_pulse = 1; #10 hit_pulse = 0;

        // Miss to reset streak
        #20 miss_pulse = 1; #10 miss_pulse = 0;

        // Build a streak up to threshold
        repeat(5) begin
            #20 hit_pulse = 1; #10 hit_pulse = 0;
        end

        // Trigger a double hit
        #20 double_hit_pulse = 1; #10 double_hit_pulse = 0;

        // Run a bit longer
        #100;
        $stop; // End simulation
    end

    // Monitor outputs
    initial begin
        $monitor("Time=%0t | score=%0d | streak reset? %b",
                 $time, score, uut.streak_cnt == 0);
    end

endmodule
