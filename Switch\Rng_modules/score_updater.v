module score_updater #(
    parameter int BONUS_THRESH = 5,
    parameter int BONUS_POINTS = 10
)(
    input  logic clk, rst,
    input  logic hit_pulse, miss_pulse,
    output logic [15:0] score
);

    logic [15:0] score_reg;
    logic [2:0]  streak_cnt;   // enough for counting to 5

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            score_reg  <= '0;
            streak_cnt <= '0;
        end else begin
            if (hit_pulse) begin
                score_reg  <= score_reg + 1'b1;
                streak_cnt <= streak_cnt + 1'b1;

                if (streak_cnt + 1 == BONUS_THRESH) begin
                    score_reg  <= score_reg + 1'b1 + BONUS_POINTS; 
                    streak_cnt <= '0; // reset streak after bonus
                end

            end else if (miss_pulse) begin
                streak_cnt <= '0;  // reset streak on miss
            end
        end
    end

    assign score = score_reg;

endmodule
