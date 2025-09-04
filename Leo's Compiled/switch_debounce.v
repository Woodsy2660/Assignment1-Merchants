module switch_debounce #(
    parameter DELAY_COUNTS = 500000  // 10ms at 50MHz
)(
    input clk,
    input switch_input,
    output reg switch_state,     // Debounced switch state (level)
    output reg switch_pressed,   // Pulse when switch goes high
    output reg switch_released   // Pulse when switch goes low
);
    
    // Synchronizer for metastability
    wire switch_sync;
    synchroniser u_sync (
        .clk(clk),
        .x(switch_input),
        .y(switch_sync)
    );
    
    // Debounce logic
    reg [19:0] counter;
    reg switch_prev;
    
    always @(posedge clk) begin
        // Debounce filter - wait for stable state
        if (switch_sync != switch_state) begin
            if (counter >= DELAY_COUNTS) begin
                switch_state <= switch_sync;
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end else begin
            counter <= 0;
        end
        
        // Edge detection on debounced signal
        switch_prev <= switch_state;
        switch_pressed <= switch_state & ~switch_prev;    // Rising edge (switch turned ON)
        switch_released <= ~switch_state & switch_prev;   // Falling edge (switch turned OFF)
    end
    
endmodule
