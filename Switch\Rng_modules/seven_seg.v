module seven_seg (
    input      [3:0]  bcd,
    output reg [6:0]  segments // Must be reg to set in always block!!
);

    // Your `always @(*)` block and case block here!
    always @(*) begin
        case (bcd)
            4'h0: segments = 7'b1000000; // Display "0" 
            4'h1: segments = 7'b1111001; // Display "1"
            4'h2: segments = 7'b0100100; // Display "2"
            4'h3: segments = 7'b0110000; // Display "3"
            4'h4: segments = 7'b0011001; // Display "4"
            4'h5: segments = 7'b0010010; // Display "5"
            4'h6: segments = 7'b0000010; // Display "6"
            4'h7: segments = 7'b1111000; // Display "7"
            4'h8: segments = 7'b0000000; // Display "8"
            4'h9: segments = 7'b0010000; // Display "9"
            default: segments = 7'b1111111; // All segments OFF (invalid input)
        endcase
    end

endmodule
