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
			2'b01: difficulty_ms = 1500;
			2'b10: difficulty_ms = 1000;
			2'b11: difficulty_ms = 750;
			default: difficulty_ms = 1500;  // fallback
		endcase
	end
	

							  
    // RNG module from lesson
    wire [3:0] random_led; 
    rng #(.OFFSET(0), .MAX_VALUE(262143), .SEED(985)) rng_inst (
        .clk(CLOCK_50),
        .random_value(random_led)
    );
	 
	 
	 ///* New rng 2 setup
	 
	 wire [3:0] random_led2; 
    rng #(.OFFSET(0), .MAX_VALUE(262143), .SEED(336)) rng_inst2 (
        .clk(CLOCK_50),
        .random_value(random_led2)
    );
	 
	 //*/
	 
    
    reg [25:0] counter;
    wire LED_toggle;
	 
	 wire [9:0] moles_hit;
	
	// activate_LED instance  
	activate_LED u_actiave_LED ( 
		.clk(CLOCK_50),
		.rst(system_reset),  // Use system_reset instead of rst
		.LED_toggle(LED_toggle),
		.rng_led(random_led[3:0]),    // Truncate to 4 bits
		.rng_led2(random_led2[3:0]),  // Truncate to 4 bits  
		.hit_LEDs(moles_hit),         // Connect hit signals from mole_detector
		.LEDR(LEDR)
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
    
    wire hit_pulse, miss_pulse;
    
    // Score Updater Module
    score_updater u_score_updater (
        .clk(CLOCK_50),
        .rst(rst),
        .hit_pulse(hit_pulse),
		  .double_hit_pulse(double_hit_pulse),
        .miss_pulse(miss_pulse),
        .score(score)
    );
    
    //  MOLE DETECTOR AND GAME CONTROLLA
		mole_detector #(.N_MOLES(10)) u_mole (
		.clk          (CLOCK_50),
		.rst          (system_reset),  // Use system_reset instead of rst
		.LED_toggle   (LED_toggle),
		.active_onehot(LEDR),
		.btn_edge     (edge_detect),
		.armed        (/* optional */),
		.hit_pulse    (hit_pulse),
		.double_hit_pulse(double_hit_pulse),
		.miss_pulse   (miss_pulse),
		.moles_hit    (moles_hit)         // Connect the hit output	
	);
 
endmodule


