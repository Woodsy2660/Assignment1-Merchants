module rng #(
    parameter OFFSET = 0,
    parameter MAX_VALUE = 262143,
    parameter SEED = 985             // Must be non-zero
) (
    input clk,
    output [4:0] random_value
);
    reg [17:0] lfsr;                 // 18-bit LFSR
    integer i;                       // for loop index
    
    // Initialize the LFSR
    initial lfsr = SEED;
    
    // Set the feedback (tap bits 18 and 11 for maximal 18-bit LFSR)
    wire feedback;
    assign feedback = lfsr[17] ^ lfsr[10];
    
    // Shift register logic
    always @(posedge clk) begin
        lfsr <= {lfsr[16:0], feedback}; // Shift left and insert feedback at LSB
    end
    
    assign random_value = lfsr % 10;
    
endmodule
