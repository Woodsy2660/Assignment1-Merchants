module mole_detector #(
  parameter int N_MOLES = 18,
  parameter int WINDOW_TICKS = 1500  // 1500 ms
)(
  input  logic                 clk, rst,
  input  logic                 tick,            // 1-ms tick from your timer
  input  logic [N_MOLES-1:0]   active_onehot,   // which LED/mole is ON
  input  logic [N_MOLES-1:0]   btn_edge,        // debounced rising-edge pulses
  output logic                 armed,           // level: waiting for a hit
  output logic                 hit_pulse,       // 1 cycle when correct hit
  output logic                 miss_pulse       // 1 cycle when window expired OR mole disappeared
);
  // ---------- state machine ----------
  typedef enum logic [1:0] { IDLE, ARMED, DONE } state_t;
  state_t state, next;
  
  // Store which mole(s) we're currently tracking
  logic [N_MOLES-1:0] tracked_mole;
  
  // match / non-match
  logic correct_press;
  assign correct_press = |(btn_edge & tracked_mole); // align press with tracked mole
  
  // miss conditions
  logic timeout_miss, disappeared_miss;
  assign timeout_miss = (win_cnt >= WINDOW_TICKS);
  assign disappeared_miss = (tracked_mole != '0) && (active_onehot == '0);
  
  // level-style output straight from the state
  assign armed = (state == ARMED);
  
  // window timing
  logic [$clog2(WINDOW_TICKS+1)-1:0] win_cnt;
  
  // next-state (combinational)
  always_comb begin
    next = state;
    unique case (state)
      IDLE  : if (active_onehot != '0)           next = ARMED;         // a mole lit
      ARMED : if (correct_press)                 next = DONE;          // hit
              else if (timeout_miss || disappeared_miss)  
                                                 next = DONE;          // timeout or mole disappeared
      DONE  : if (btn_edge == '0)                next = IDLE;          // wait for button release, then go to IDLE
    endcase
  end
  
  // sequential: state, pulses, counter, and tracked mole
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state        <= IDLE;
      win_cnt      <= '0;
      hit_pulse    <= 1'b0;
      miss_pulse   <= 1'b0;
      tracked_mole <= '0;
    end else begin
      state <= next;
      
      // Track which mole we're currently watching
      if (state == IDLE && active_onehot != '0) begin
        tracked_mole <= active_onehot;  // Latch the current active mole(s)
      end else if (state == DONE) begin
        tracked_mole <= '0;             // Clear tracking when round is done
      end
      
      // 1-cycle pulses when leaving ARMED
      hit_pulse  <= (state == ARMED) &&  correct_press;
      miss_pulse <= (state == ARMED) && !correct_press && (timeout_miss || disappeared_miss);
      
      // window counter runs only while ARMED
      if (state == ARMED) begin
        if (tick) win_cnt <= win_cnt + 1'b1;
      end else begin
        win_cnt <= '0;
      end
    end
  end
endmodule
