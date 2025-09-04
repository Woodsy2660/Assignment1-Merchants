module top_level ( 
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [17:0] SW,
    output reg  [17:0] LEDR,
    output reg  [8:0]  LEDG
    output [6:0]  HEX0, HEX1, HEX2, HEX3 // Four 7-segment displays
);
    wire rst = ~KEY[0];
    
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
        .random_value(random_value),
		.LEDR(LEDR)
    );


    // Game speed setting (from switches or fixed param)
    // Example: each "game_speed" is in milliseconds
    wire [9:0] game_speed = {SW[9:1]};  // use switches to change tick speed

    // Timer instance
    timer #(
        .MAX_MS(1000)   // can adjust max interval as needed
    ) timer_inst (
        .clk(CLOCK_50),
        .reset(rst),
        .CLKS_PER_MS(50000),           // 50 MHz clock = 50,000 cycles per ms
        .up(1'b1),                     // count upwards
        .start_value(0),               // start at 0
        .enable(1'b1),                 // always enabled
        .timer_value(),                // unused for now
		.LED_toggle(LED_toggle)          // 1-cycle pulse every "game_speed"
    );
    

    wire [17:0] debounced_switches;
    wire [17:0] rise_detect, fall_detect, edge_detect;
    
	 // Switch signal debouncer
    debouncer #(.WIDTH(18), .CNT_MAX(2500)) deb_inst (
        .clk(CLOCK_50),
        .noisy(SW),
        .clean(debounced_switches)
    );
    
	 // Simple edge detector
    switch_detector #(.WIDTH(18)) detector_inst (
        .clk(CLOCK_50),
        .rst(rst),
        .signal(debounced_switches),
        .rise_detect(rise_detect),
        .fall_detect(fall_detect),
        .edge_detect(edge_detect)
    );

    reg [10:0] score;

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
    .miss_pulse(miss_pulse),
    .score(score)
	);
	

    
	// Logic block, turns on a random LED, turns off when edge detected, might need to be an FSM for final product
	// REPLACE THIS WITH MOLE DETECTOR AND GAME CONTROLLA

	mole_detector #(.N_MOLES(18), .WINDOW_TICKS(1500)) u_mole (
	  .clk          (CLOCK_50),
	  .rst          (rst),
	  .tick         (LED_toggle),     // real 1 ms tick
	  .active_onehot(LEDR),         // LEVEL: which LEDs are currently lit
	  .btn_edge     (rise_detect),  // PULSE: which button(s) rose this clock
	  .armed        (/* optional */),
	  .hit_pulse    (hit_pulse),
	  .miss_pulse   (miss_pulse)
	);
 
 endmodule
 
