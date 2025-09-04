module Assignment1Test ( 
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [9:0] SW,
    output wire [9:0] LEDR,  // Changed from 'reg' to 'wire'
    output reg  [8:0]  LEDG,
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
        .rng_led(random_led),
		  .hit_pulse(hit_pulse),// Changed from random_value to random_led
        .LEDR(LEDR)  // Connect directly to output wire
    );
    
    // Game speed setting (from switches or fixed param)
    // Example: each "game_speed" is in milliseconds
    wire [9:0] game_speed = SW[9:0];  // Fixed: use all 10 switches
    
    // Timer instance
    timer #(
        .MAX_MS(1000)   // can adjust max interval as needed
    ) timer_inst (
        .clk(CLOCK_50),
        .reset(rst),        
        .up(1'b1),                     // count upwards
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
        .miss_pulse(miss_pulse),
        .score(score)
    );
    
    // Logic block, turns on a random LED, turns off when edge detected, might need to be an FSM for final product
    // REPLACE THIS WITH MOLE DETECTOR AND GAME CONTROLLA
    mole_detector #(.N_MOLES(10), .WINDOW_TICKS(1500)) u_mole (  // Fixed: N_MOLES should be 10 for LEDR[9:0]
        .clk          (CLOCK_50),
        .rst          (rst),
        .tick         (LED_toggle),     // real 1 ms tick
        .active_onehot(LEDR),          // LEVEL: which LEDs are currently lit
        .btn_edge     (edge_detect),   // PULSE: which button(s) rose this clock
        .armed        (/* optional */),
        .hit_pulse    (hit_pulse),
        .miss_pulse   (miss_pulse)
    );
 
endmodule
