module top_level ( 
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [17:0] SW,
    output reg  [17:0] LEDR,
    output reg  [8:0]  LEDG
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
    
	 
	 // Needs to be replaced with a timmer module maybe (?)
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
        .sig(debounced_switches),
        .rise_detect(rise_detect),
        .fall_detect(fall_detect),
        .edge_detect(edge_detect)
    );
    
	// Logic block, turns on a random LED, turns off when edge detected
    integer j;
    always @(posedge CLOCK_50) begin
        if (rst) begin
            LEDR <= 18'h00000;
        end else if (LED_toggle) begin
			LEDR[random_led] <= 1'b1; 
			end else begin
            for (j = 0; j < 18; j = j + 1) begin
                if (edge_detect[j]) begin
                    LEDR[j] <= 1'b0;
                end
            end
        end
    end
 
 endmodule
 
