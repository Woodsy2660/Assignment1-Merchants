module mole_detector #(
  parameter int N_MOLES = 10
)(
  input  logic                 clk, rst,
  input  logic                 LED_toggle,      // Pulse from timer - defines mole window
  input  logic [N_MOLES-1:0]   active_onehot,   // which LED/mole is ON
  input  logic [N_MOLES-1:0]   btn_edge,        // debounced rising-edge pulses
  output logic                 armed,           // level: waiting for a hit
  output logic [N_MOLES-1:0]   hit_pulse,       // 1 cycle per correct hit
  output logic [N_MOLES-1:0]   miss_pulse       // 1 cycle per miss
);

  // ---------- state machine ----------
  typedef enum logic [1:0] { IDLE, ARMED, DONE } state_t;
  state_t state, next;

  // Track which mole(s) are currently armed
  logic [N_MOLES-1:0] tracked_mole;

  // Hit detection per mole
  logic [N_MOLES-1:0] correct_press;
  assign correct_press = btn_edge & tracked_mole;

  // Timeout/miss per mole
  logic [N_MOLES-1:0] timeout_miss;
  assign timeout_miss = LED_toggle & tracked_mole;

  // Armed output
  assign armed = |tracked_mole;

  // Next-state logic
  always_comb begin
    next = state;
    unique case (state)
      IDLE  : if (active_onehot != '0') next = ARMED;
      ARMED : if (|correct_press || |timeout_miss) next = DONE;
      DONE  : next = (active_onehot == '0') ? IDLE : ARMED;
    endcase
  end

  // Sequential logic
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state        <= IDLE;
      tracked_mole <= '0;
      hit_pulse    <= '0;
      miss_pulse   <= '0;
    end else begin
      state <= next;

      // Update tracked_mole: accumulate active LEDs while ARMED
      if (next == ARMED) begin
        tracked_mole <= tracked_mole | active_onehot; // add any newly lit LEDs
      end else if (next == IDLE) begin
        tracked_mole <= '0; // clear all when returning to IDLE
      end

      // Generate hit/miss pulses per mole
      hit_pulse  <= correct_press;
      miss_pulse <= timeout_miss & ~correct_press;

      // Remove moles that were hit or missed
      tracked_mole <= tracked_mole & ~(hit_pulse | miss_pulse);
    end
  end

endmodule
