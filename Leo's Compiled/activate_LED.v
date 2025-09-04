module activate_LED (
    input        clk,
    input        rst,
    input        LED_toggle,       // from timer (one pulse per cycle)
    input  [3:0] rng_led,          // from RNG (0-9 for 10 LEDs)
    input        hit_pulse,        // 1-cycle pulse from mole_detector
    output reg [9:0] LEDR          // drives LEDs (10 LEDs: 0-9)
);
    reg [3:0] current_led;  // which LED is active (4 bits for 0-9)
    reg       mole_active;  // keeps track if LED is on
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_led <= 4'd0;
            mole_active <= 1'b0;
        end else begin
            // Turn on new mole on LED_toggle
            if (LED_toggle) begin
                current_led <= rng_led;
                mole_active <= 1'b1;
            end
            // Turn off LED if mole was hit
            if (hit_pulse && mole_active)
                mole_active <= 1'b0;
        end
    end
    
    always @(*) begin
        LEDR = 10'b0;
        if (mole_active && current_led < 10)  // bounds check
            LEDR[current_led] = 1'b1;
    end
endmodule
