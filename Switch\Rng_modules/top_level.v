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
    reg LED_toggle;


	// Turn on LED Module
	activate_LED u_actiave_LED ( 
        .clk(CLOCK_50),
		.rst(rst),
		.LED_toggle(LED_toggle),
        .random_value(random_value),
		.LEDR(LEDR)
    );


	// HENRY PUT TIMER MODULE HERE. WE NEED IT TO ACTIAVTE LED_toggle EVERY game_speed
	// It needs to take in an input game_speed, and then LED_toggle is toggled once every game_speed cycle. This is so we can implement multiple levels with the state machine.

    always @(posedge CLOCK_50) begin
        if (rst) begin
            counter <= 0;
            LED_toggle <= 1'b0;
        end else begin
            if (counter >= 26'd50000000) begin // 1 sec
                counter <= 0;
                LED_toggle <= 1'b1;
            end else begin
                counter <= counter + 1;
                LED_toggle <= 1'b0;
            end
        end
    end
    

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
 
