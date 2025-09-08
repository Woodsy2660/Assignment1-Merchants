module timer_tb;    
	// Simulation parameters
    parameter SIM_CLKS_PER_MS = 250;  // 250 cycles = 5 µs at 50 MHz
    parameter SIM_MAX_MS      = 2;    // rollover every tick

    reg         clk, reset, up, enable;
    reg  [15:0] start_value;   
    wire [15:0] timer_value;  
    wire        LED_toggle;

    // Instantiate timer
    timer #(
        .CLKS_PER_MS(SIM_CLKS_PER_MS)   // now CLKS_PER_MS is overridden
    ) DUT (
        .clk(clk),
        .reset(reset),
        .up(up),
        .max_ms(SIM_MAX_MS),
        .start_value(start_value),
        .enable(enable),
        .timer_value(timer_value),
        .LED_toggle(LED_toggle)
    );

    // Clock generation: 50 MHz (20 ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, timer_tb);

        enable      = 1'b1;
        up          = 1'b1;
        start_value = 0;

        // --- Count-up test ---
        reset = 1'b1; #20; reset = 1'b0;

        repeat(2000) begin
            #20;
            if (LED_toggle) 
                $display("t=%0dns: LED_toggle pulse detected! timer_value=%0d", $time, timer_value);
        end

        $finish;
    end
endmodule