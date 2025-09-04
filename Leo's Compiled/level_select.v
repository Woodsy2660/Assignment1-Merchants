module level_select #(
    parameter DELAY_COUNTS = 500000  // 10ms at 50MHz for debouncing
)(
    input  logic       clk,
    input  logic       rst,           // Global reset (KEY[0])
    input  logic [3:1] keys,          // KEY[3:1] for level selection
    output logic [1:0] current_level, // Current selected level (1, 2, or 3)
    output logic       level_reset    // Pulse when level changes (to reset score/system)
);
    
    // Debounced key signals
    logic [3:1] key_states;     // Debounced key states (active low)
    logic [3:1] key_pressed;    // Rising edge pulses (key press detection)
    logic [3:1] key_released;   // Falling edge pulses
    
    // Generate debounce modules for each key
    genvar i;
    generate
        for (i = 1; i <= 3; i = i + 1) begin : key_deb_gen
            // Note: KEY inputs are active low, so we invert them
            switch_debounce #(.DELAY_COUNTS(DELAY_COUNTS)) u_key_deb (
                .clk(clk),
                .switch_input(~keys[i]),        // Invert because KEYs are active low
                .switch_state(key_states[i]),   // This will be high when key is pressed
                .switch_pressed(key_pressed[i]), // Pulse when key goes from released to pressed
                .switch_released(key_released[i])
            );
        end
    endgenerate
    
    // Level selection logic
    logic [1:0] next_level;
    logic level_changed;
    
    always @(*) begin
        next_level = current_level;  // Default: keep current level
        level_changed = 1'b0;
        
        // Priority: KEY[1] = Level 1, KEY[2] = Level 2, KEY[3] = Level 3
        if (key_pressed[1]) begin
            next_level = 2'd1;
            level_changed = 1'b1;
        end else if (key_pressed[2]) begin
            next_level = 2'd2;
            level_changed = 1'b1;
        end else if (key_pressed[3]) begin
            next_level = 2'd3;
            level_changed = 1'b1;
        end
    end
    
    // Sequential logic for level and reset pulse generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_level <= 2'd1;    // Default to level 1
            level_reset   <= 1'b0;
        end else begin
            current_level <= next_level;
            level_reset   <= level_changed;  // Pulse for one cycle when level changes
        end
    end
    
endmodule
