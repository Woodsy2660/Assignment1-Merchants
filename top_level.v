module top_level (
    input         CLOCK_50,              // 50MHz clock signal
    input  [3:0]  KEY,                   // The 4 push buttons on the board
    output [9:0]  LEDR,                  // 10 red LEDs (DE1-SoC)
    output [6:0]  HEX0, HEX1, HEX2, HEX3 // Four 7-segment displays
);

    // Intermediate wires:
    wire        timer_reset, timer_up, timer_enable, button_pressed;
    wire [10:0] timer_value, random_value;
    
    // Turn off unused LEDs
    assign LEDR[9:1] = 9'b0;

    // Timer module with correct 50MHz parameters
    timer #(
        .CLKS_PER_MS(50000)  // 50MHz / 1000 = 50,000 clocks per ms
    ) u_timer ( 
        .clk(CLOCK_50),
        .reset(timer_reset),
        .up(timer_up),
        .enable(timer_enable),
        .start_value(random_value),
        .timer_value(timer_value)
    );

    // Debounce with proper delay and inverted button
    debounce #(
        .DELAY_COUNTS(500000)  // 10ms debounce at 50MHz
    ) u_debounce (
        .clk(CLOCK_50),
        .button(~KEY[0]),  // INVERT active-low button
        .button_pressed(button_pressed)
    );

    // RNG module
    rng u_rng (
        .clk(CLOCK_50),
        .random_value(random_value)
    );

    // Display module
    display u_display ( 
        .clk(CLOCK_50),
        .value(timer_value), 
        .display0(HEX0),
        .display1(HEX1),
        .display2(HEX2),
        .display3(HEX3)
    );

    // FSM controller
    reaction_time_fsm u_reaction_time_fsm (
        .clk(CLOCK_50),
        .button_pressed(button_pressed),
        .timer_value(timer_value),
        .reset(timer_reset),
        .up(timer_up),
        .enable(timer_enable),
        .led_on(LEDR[0])
    );

endmodule