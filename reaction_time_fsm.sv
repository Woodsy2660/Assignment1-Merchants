module reaction_time_fsm #(
    parameter MAX_MS=2047    
)(
    input logic                             clk,
    input logic                             button_pressed,
    input logic        [$clog2(MAX_MS)-1:0] timer_value,
    output logic                      reset,
    output logic                      up,
    output logic                      enable,
    output logic                      led_on
);

    // Edge detection block here!
    logic prev_button_pressed;
    logic button_edge;

    always_ff @(posedge clk) begin 
        prev_button_pressed <= button_pressed;
    end

    assign button_edge = ~prev_button_pressed & button_pressed;

    // State typedef enum here! (See 3.1 code snippets)
    typedef enum logic [1:0] {
        S0_INITIALISE,
        S1_COUNT_DOWN,
        S2_COUNT_UP,
        S3_PAUSE_TIMER
    } state_type;

    state_type current_state, next_state;


    always_comb begin 

        next_state = current_state;

        case (current_state) 
            S0_INITIALISE: begin
                if (button_edge)
                    next_state = S1_COUNT_DOWN;
            end

            S1_COUNT_DOWN: begin
                if (timer_value == 0)
                    next_state = S2_COUNT_UP;
                else if (button_edge)
                    next_state = S0_INITIALISE;
            end

            S2_COUNT_UP: begin
                if (button_edge)
                    next_state = S3_PAUSE_TIMER;
            end

            S3_PAUSE_TIMER: begin
                if (button_edge)
                    next_state = S0_INITIALISE;
            end

        endcase
    end
    
    // always_ff for FSM state variable flip-flops here! (See 3.1 code snippets)
    // Set the current state as the next state (Think about whether a blocking or non-blocking assignment should be used here)

    always_ff @(posedge clk) begin 
        current_state <= next_state;
    end 

    // Continuously assign outputs of reset, up, enable and led_on based on the current state here! (See 3.1 code snippets)

    always_comb begin 
    
        reset = 1'b0;
        up = 1'b0;
        enable = 1'b0;
        led_on = 1'b0;

        case (current_state)

            S0_INITIALISE: begin
                reset = 1'b1;      // Reset timer to random value
                up = 1'b0;         // Configure for countdown mode
                enable = 1'b0;     // Keep timer disabled
                led_on = 1'b0;     // LED off
            end
            
            S1_COUNT_DOWN: begin
                reset = (timer_value == 0);  // Mealy output: reset when countdown reaches 0
                up = 1'b0;         // When reset occurs, configure for count-up mode  
                enable = 1'b1;     // Enable timer counting
                led_on = 1'b0;     // LED off during countdown
            end
            
            S2_COUNT_UP: begin
                reset = 1'b0;      // Don't reset timer
                up = 1'b1;         // Count up (direction set during previous reset)
                enable = 1'b1;     // Keep timer running to measure reaction
                led_on = 1'b1;     // LED ON - player should react!
            end
            
            S3_PAUSE_TIMER: begin
                reset = 1'b0;      // Keep timer value
                up = 1'b0;         // Direction irrelevant when paused
                enable = 1'b0;     // PAUSE timer to display final score
                led_on = 1'b0;     // Turn LED off
            end
        endcase
    end

endmodule