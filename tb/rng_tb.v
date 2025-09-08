`timescale 1ns/1ps

module rng_tb;

    // Testbench signals
    reg clk;
    wire [3:0] random_value;

    // Instantiate RNG
    rng #(
        .OFFSET(0),
        .MAX_VALUE(262143),
        .SEED(985)
    ) uut (
        .clk(clk),
        .random_value(random_value)
    );

    // Clock generation: 10 ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        #200;        // run for 200 ns
        $stop;       // stop simulation
    end

endmodule
