module Assignment1Test ( 
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [9:0] SW,
    output wire [9:0] LEDR,  // Changed from 'reg' to 'wire'
    output reg  [8:0]  LEDG,
    output [6:0]  HEX0, HEX1, HEX2, HEX3 // Four 7-segment displays
);
    wire rst = ~KEY[0];
	 
	 // level select module
	 
	 
	 // Level select module
	wire [1:0] current_level;
	wire level_reset;
	wire system_reset = rst | level_reset;  // Combine global reset with level reset

	level_select #(.DELAY_COUNTS(500000)) u_level_select (
		.clk(CLOCK_50),
		.rst(rst),
		.keys(KEY[3:1]),
		.current_level(current_level),
		.level_reset(level_reset)
	);
	
	reg [31:0] difficulty_ms;

	always @(*) begin
		case (current_level)
			2'b00: difficulty_ms = 1500;
			2'b01: difficulty_ms = 1000;
			2'b10: difficulty_ms = 750;
			default: difficulty_ms = 1500;  // fallback
		endcase
	end
	

							  
    // RNG module from lesson
    wire [4:0] random_led; 
    rng #(.OFFSET(0), .MAX_VALUE(262143), .SEED(985)) rng_inst (
        .clk(CLOCK_50),
        .random_value(random_led)
    );
    
    reg [25:0] counter;
    wire LED_toggle;
    
    // Turn on LED Module
    activate_LED u_actiave_LED ( 
        .clk(CLOCK_50),
        .rst(rst),
        .LED_toggle(LED_toggle),
        .rng_led(random_led),
		  .hit_pulse(hit_pulse),// Changed from random_value to random_led
        .LEDR(LEDR)  // Connect directly to output wire
    );
    
    // Game speed setting (from switches or fixed param)
    // Example: each "game_speed" is in milliseconds
    wire [9:0] game_speed = SW[9:0];  // Fixed: use all 10 switches
    
    // Timer instance
    timer timer_inst (
        .clk(CLOCK_50),
        .reset(rst),        
        .up(1'b1),                     // count upwards
		  .max_ms(difficulty_ms),
        .start_value(0),               // start at 0
        .enable(1'b1),                 // always enabled
        .timer_value(),                // unused for now
        .LED_toggle(LED_toggle)        // 1-cycle pulse every "game_speed"
    );
    
    // Switch debouncing for all 10 switches
    wire [9:0] switch_states;     // Debounced switch states
    wire [9:0] switch_pressed;    // Rising edge pulses
    wire [9:0] switch_released;   // Falling edge pulses
    
    // Generate debounce modules for each switch
    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : switch_deb_gen
            switch_debounce #(.DELAY_COUNTS(500000)) u_switch_deb (
                .clk(CLOCK_50),
                .switch_input(SW[i]),
                .switch_state(switch_states[i]),
                .switch_pressed(switch_pressed[i]),
                .switch_released(switch_released[i])
            );
        end
    endgenerate
    
    // Use the pressed signals for edge detection
    wire [9:0] edge_detect = switch_pressed;
    
    wire [10:0] score;
    
    // Display module
    display u_display ( 
        .clk(CLOCK_50),
        .value(score), 
        .display0(HEX0),
        .display1(HEX1),
        .display2(HEX2),
        .display3(HEX3)
    );
    
	wire [9:0] hit_pulse;
	wire [9:0] miss_pulse;
	wire single_hit = |hit_pulse; 
	wire single_miss = |miss_pulse;

    
    // Score Updater Module
    score_updater u_score_updater (
        .clk(CLOCK_50),
        .rst(rst),
		.hit_pulse(single_hit),
		.miss_pulse(single_miss),
        .score(score)
    );
    
    // Logic block, turns on a random LED, turns off when edge detected, might need to be an FSM for final product
    // REPLACE THIS WITH MOLE DETECTOR AND GAME CONTROLLA
    mole_detector #(.N_MOLES(10)) u_mole (
    	.clk          (CLOCK_50),
    	.rst          (rst),
    	.LED_toggle   (LED_toggle),
    	.active_onehot(LEDR),
    	.btn_edge     (edge_detect),
    	.armed        (/* optional */),
    	.hit_pulse    (hit_pulse),
    	.miss_pulse   (miss_pulse)
	);

 
endmodule
