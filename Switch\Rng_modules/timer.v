`timescale 1ns/1ns /* This directive (`) specifies simulation <time unit>/<time precision>. */

module timer #(
    parameter MAX_MS = 2047,            // Maximum millisecond value
    parameter CLKS_PER_MS = 20 // What is the number of clock cycles in a millisecond?
) (
    input                       clk,
    input                       reset,
    input                       up,
    input  [$clog2(MAX_MS)-1:0] start_value, // What does the $clog2() function do here?
    input                       enable,
    output [$clog2(MAX_MS)-1:0] timer_value
);

    // Your code here!
    reg [$clog2(CLKS_PER_MS)-1:0] clk_cycle_counter;
    reg [$clog2(MAX_MS)-1:0] ms_counter;

    reg count_up;
    
    always @(posedge clk) begin
        if (reset) begin
            clk_cycle_counter <= 0;
            if (up) begin
                ms_counter <= 0;
                count_up <= 1'b1;
            end
            else begin
                ms_counter <= start_value;
                count_up <= 1'b0;
            end
        end
        else if (enable) begin
            if (clk_cycle_counter >= (CLKS_PER_MS - 1)) begin
                clk_cycle_counter <= 0;
                if (count_up) begin
                    ms_counter <= ms_counter + 1;
                end
                else begin
                    ms_counter <= ms_counter - 1;
                end
            end 
            else begin
                clk_cycle_counter <= clk_cycle_counter + 1;
            end
        end
    end

    assign timer_value = ms_counter;

endmodule



