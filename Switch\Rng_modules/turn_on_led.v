module activate_LED (
    input        clk,
    input        rst,
    input        LED_toggle,       // from timer (one pulse per cycle)
    input  [4:0] random_value,     // from RNG (0–17)
    output reg [17:0] LEDR         // drives LEDs
);

    reg [4:0] current_led;  // which LED is active

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_led <= 5'd0;
        end 
        else if (LED_toggle) begin
            current_led <= rng_led;   // pick new random LED only on toggle
        end
    end

    always @(*) begin
        LEDR = 18'b0;
        LEDR[current_led] = 1'b1;     // turn on current LED
    end

endmodule
