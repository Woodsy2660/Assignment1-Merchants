module rng2 #(
    parameter OFFSET = 0,
    parameter MAX_VALUE = 262143,
    parameter SEED = 535             // Must be non-zero
) (
    input clk,
    output [3:0] random_value2        // Changed to 4 bits for 0-9 range
);
    reg [9:0] lfsr;                  // 10-bit LFSR
    integer i;                       // for loop index
    
    // Initialize the LFSR
    initial lfsr = SEED[9:0];        // Use lower 10 bits of seed
    
    // Set the feedback (tap bits 10 and 7 for maximal 10-bit LFSR)
    wire feedback;
    assign feedback = lfsr[9] ^ lfsr[6];
    
    // Shift register logic
    always @(posedge clk) begin
        lfsr <= {lfsr[8:0], feedback}; // Shift left and insert feedback at LSB
    end
    
    // Convert LFSR output to 0-9 range
    assign random_value2 = (lfsr % 10);
    
endmodule
