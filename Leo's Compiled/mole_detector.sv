module mole_detector #(
  parameter int N_MOLES = 10;
)(
  input  logic                 clk, rst,
  input  logic                 led_toggle,      // Pulse from timer - defines mole window
  input  logic [N_MOLES-1:0]   active_onehot,   // which LED/mole is ON
  input  logic [N_MOLES-1:0]   btn_edge,        // debounced rising-edge pulses
  output logic                 armed,           // level: waiting for a hit
  output logic                 hit_pulse,       // 1 cycle when correct hit
  output logic                 miss_pulse       // 1 cycle when mole window expires
);
  // ---------- state machine ----------
  typedef enum logic [1:0] { IDLE, ARMED, DONE } state_t;
  state_t state, next;
  
  // Store which mole(s) we're currently tracking
  logic [N_MOLES-1:0] tracked_mole;
  
  // match / non-match - use tracked_mole for consistency
  logic correct_press;
  assign correct_press = |(btn_edge & tracked_mole); // Check against tracked moles
  
  // miss condition - LED_toggle pulse while still armed means time's up
  logic timeout_miss, disappeared_miss;
  assign timeout_miss = led_toggle && (state == ARMED);  // LED_toggle pulse = window expired
  assign disappeared_miss = (tracked_mole != '0) && (active_onehot == '0);
  
  // level-style output straight from the state
  assign armed = (state == ARMED);
  
  // next-state (combinational)
  always_comb begin
    next = state;
    unique case (state)
      IDLE  : if (active_onehot != '0)           next = ARMED;         // a mole lit
      ARMED : if (correct_press)                 next = DONE;          // hit
              else if (timeout_miss || disappeared_miss)  
                                                 next = DONE;          // timeout or mole disappeared
      DONE  : next = IDLE;                       // Always go back to IDLE after one cycle
    endcase
  end
  
  // sequential: state, pulses, and tracked mole
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state        <= IDLE;
      hit_pulse    <= 1'b0;
      miss_pulse   <= 1'b0;
      tracked_mole <= '0;
    end else begin
      state <= next;
      
      // Track which mole we're currently watching
      if (next == ARMED && state == IDLE) begin
        tracked_mole <= active_onehot;  // Latch the mole when entering ARMED
      end else if (next == IDLE) begin
        tracked_mole <= '0;             // Clear tracking when going to IDLE
      end
      
      // 1-cycle pulses when transitioning out of ARMED
      hit_pulse  <= (state == ARMED) && (next == DONE) && correct_press;
      miss_pulse <= (state == ARMED) && (next == DONE) && !correct_press;
    end
  end
endmodule
