


module change_level_difficulty ( 
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [17:0] SW,
    output reg  [17:0] LEDR,
    output reg  [8:0]  LEDG
    output [6:0]  HEX0, HEX1, HEX2, HEX3 // Four 7-segment displays
);



    