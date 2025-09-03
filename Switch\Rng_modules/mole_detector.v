module mole_detector #(
  parameter int N_MOLES = 17,
  parameter int WINDOW_TICKS = 1500  // 1500 ms
)(
  input  logic                 clk, rst,
  input  logic                 tick,            // 1-ms tick from your timer
  input  logic [N_MOLES-1:0]   active_onehot,   // which LED/mole is ON
  input  logic [N_MOLES-1:0]   btn_edge,        // debounced rising-edge pulses
  output logic                 armed,           // level: waiting for a hit
  output logic                 hit_pulse,       // 1 cycle when correct hit
  output logic                 miss_pulse       // 1 cycle when window expired
);

  // ---------- state machine ----------
  typedef enum logic [1:0] { IDLE, ARMED, DONE } state_t;
  state_t state, next;

  // match / non-match
  logic correct_press;
  assign correct_press = |(btn_edge & active_onehot); // align press with lit mole

  // level-style output straight from the state
  assign armed = (state == ARMED);

  // window timing
  logic [$clog2(WINDOW_TICKS+1)-1:0] win_cnt;

  // next-state (combinational)
  always_comb begin
    next = state;
    unique case (state)
      IDLE  : if (active_onehot != '0)           next = ARMED;         // a mole lit
      ARMED : if (correct_press)                 next = DONE;          //hit
              else if (win_cnt >= WINDOW_TICKS)  next = DONE;          // timeout
      DONE  : if (active_onehot == '0 && btn_edge == '0)
                                                next = IDLE;           // round cleared
    endcase
  end

  // sequential: state, pulses, and counter
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state      <= IDLE;
      win_cnt    <= '0;
      hit_pulse  <= 1'b0;
      miss_pulse <= 1'b0;
    end else begin
      state <= next;

      // 1-cycle pulses when leaving ARMED
      hit_pulse  <= (state == ARMED) &&  correct_press;
      miss_pulse <= (state == ARMED) && !correct_press && (win_cnt >= WINDOW_TICKS);

      // window counter runs only while ARMED
      if (state == ARMED) begin
        if (tick) win_cnt <= win_cnt + 1'b1;
      end else begin
        win_cnt <= '0;
      end
    end
  end

endmodule
