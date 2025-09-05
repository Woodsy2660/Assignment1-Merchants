module activate_LED (
    input        clk,
    input        rst,
    input        LED_toggle,       // from timer (one pulse per cycle)
    input  [3:0] rng_led,          // from RNG (0-9 for 10 LEDs)
	 input  [3:0] rng_led2,          // from RNG (0-9 for 10 LEDs)
    input  [9:0] hit_LEDs,   // one-hot vector of hit moles instead of a simple one-cycle pulse
    output reg [9:0] LEDR          // drives LEDs (10 LEDs: 0-9)
);
    reg [9:0] current_leds;  // which LED is active (4 bits for 0-9)
//    reg       mole_active;  // keeps track if LED is on (but mole_active only useful for single led)
    
	 wire [3:0] clamped_rng1 = rng_led % 10;
	 wire [3:0] clamped_rng2 = rng_led2 % 10;

    always @(posedge clk or posedge rst) begin
		if (rst)
			current_leds <= 10'b0;
		else begin
			if (LED_toggle) begin
            // Turn off ALL current moles (timeout) and turn on new ones
					current_leds <= (1'b1 << clamped_rng1) | (1'b1 << clamped_rng2);
			end
			else begin
            // Turn off only hit moles during the active period
            current_leds <= current_leds & ~hit_LEDs;
			end
		end
	end

    always @(*) begin
        LEDR = current_leds;
    end
	



endmodule



/* Old working module as of thursday night: */

//module activate_LED (
//    input        clk,
//    input        rst,
//    input        LED_toggle,       // from timer (one pulse per cycle)
//    input  [3:0] rng_led,          // from RNG (0-9 for 10 LEDs)
//	 input  [3:0] rng_led2,          // from RNG (0-9 for 10 LEDs)
//    input        hit_pulse,        // 1-cycle pulse from mole_detector
//    output reg [9:0] LEDR          // drives LEDs (10 LEDs: 0-9)
//);
//    reg [3:0] current_led;  // which LED is active (4 bits for 0-9)
//    reg       mole_active;  // keeps track if LED is on
//    
//    always @(posedge clk or posedge rst) begin
//        if (rst) begin
//            current_led <= 4'd0;
//            mole_active <= 1'b0;
//        end else begin
//            // Turn on new mole on LED_toggle
//            if (LED_toggle) begin
//                current_led <= rng_led;
//                mole_active <= 1'b1;
//            end
//            // Turn off LED if mole was hit
//            if (hit_pulse && mole_active)
//                mole_active <= 1'b0;
//        end
//    end
//    
//    always @(*) begin
//        LEDR = 10'b0;
//        if (mole_active && current_led < 10)  // bounds check
//            LEDR[current_led] = 1'b1;
//    end
//endmodule
