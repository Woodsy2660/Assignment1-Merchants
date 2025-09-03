`timescale 1ns/1ns 

module timer #(
    parameter MAX_MS = 1000   // Maximum millisecond value (default = 1000 ms = 1 second)
) (
    input [3:0]               CLKS_PER_MS, // Number of clock cycles per ms (set based on clk freq)
    input                      clk,
    input                      reset,
    input                      up,
    input  [$clog2(MAX_MS)-1:0] start_value,
    input                      enable,
    output [$clog2(MAX_MS)-1:0] timer_value,
    output reg                 LED_toggle    // pulse every ~1s
);

    // Internal registers
    reg [$clog2(CLKS_PER_MS)-1:0] clk_cycle_counter;
    reg [$clog2(MAX_MS)-1:0] ms_counter;
    reg count_up;

    always @(posedge clk) begin
        if (reset) begin
            clk_cycle_counter <= 0;
            LED_toggle <= 0;
            if (up) begin
                ms_counter <= 0;
                count_up <= 1'b1;
            end else begin
                ms_counter <= start_value;
                count_up <= 1'b0;
            end
        end else if (enable) begin
            LED_toggle <= 0; // default low each cycle

            if (clk_cycle_counter >= (CLKS_PER_MS - 1)) begin
                clk_cycle_counter <= 0;
                if (count_up) begin
                    if (ms_counter == MAX_MS-1) begin
                        ms_counter <= 0;
                        LED_toggle <= 1;   // pulse when rollover
                    end else begin
                        ms_counter <= ms_counter + 1;
                    end
                end else begin
                    if (ms_counter == 0) begin
                        ms_counter <= MAX_MS-1;
                        LED_toggle <= 1;   // pulse when rollover
                    end else begin
                        ms_counter <= ms_counter - 1;
                    end
                end
            end else begin
                clk_cycle_counter <= clk_cycle_counter + 1;
            end
        end
    end

    assign timer_value = ms_counter;

endmodule
