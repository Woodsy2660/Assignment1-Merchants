
module synchroniser_tb;
    reg clk;
    reg x;
    wire y;    


    // Instantiate the  module
    synchroniser dut (
        .clk(clk),
        .x(x),
        .y(y)
    );

    // Clock generation: 
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Testing
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars();
         
        x = 0;

        #15 x = 1;   // at t = 15, make x high
        #25 x = 0;   
        #30 x = 1;  
        #40 x = 0;  

//        #50;


        $finish(); // End simulation
    end

    always @(posedge clk) begin
    $display("t=%0t | y=%b", $time, y);
    end

endmodule
