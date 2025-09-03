module mole_controller (
    input        clk,
    input        rst,
    input        LED_toggle,       // from timer (one pulse per cycle)
    input  [4:0] rng_led,          // from RNG (0–17)
    input        hit_pulse,        // 1-cycle pulse from mole_detector
    output reg [17:0] LEDR         // drives LEDs
);

    reg [4:0] current_led;  // which LED is active
    reg       mole_active;  // keeps track if LED is on

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_led <= 5'd0;
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
        LEDR = 18'b0;
        if (mole_active)
            LEDR[current_led] = 1'b1;
    end

endmodule
