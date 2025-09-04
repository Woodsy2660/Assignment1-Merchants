module score_updater #(
    parameter BONUS_THRESH = 5,
    parameter BONUS_POINTS = 10
)(
    input wire clk, rst,
    input wire hit_pulse, miss_pulse,
    output wire [15:0] score
);
    reg [15:0] score_reg;
    reg [2:0]  streak_cnt;   // enough for counting to 5
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            score_reg  <= 16'b0;
            streak_cnt <= 3'b0;
        end else begin
            if (hit_pulse) begin
                if (streak_cnt + 1 == BONUS_THRESH) begin
                    // Award normal point + bonus points when reaching threshold
                    score_reg  <= score_reg + 1'b1 + BONUS_POINTS; 
                    streak_cnt <= 3'b0; // reset streak after bonus
                end else begin
                    // Normal hit: just add 1 point and increment streak
                    score_reg  <= score_reg + 1'b1;
                    streak_cnt <= streak_cnt + 1'b1;
                end
            end else if (miss_pulse) begin
                streak_cnt <= 3'b0;  // reset streak on miss
                // score_reg unchanged on miss
            end
        end
    end
    
    assign score = score_reg;
endmodule
