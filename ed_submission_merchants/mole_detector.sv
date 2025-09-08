module mole_detector #(
  parameter int N_MOLES = 10
)(
  input  logic                 clk,
  input  logic                 rst,
  input  logic                 LED_toggle,      // Pulse from timer - defines mole window end
  input  logic [N_MOLES-1:0]   active_onehot,   // which LED/mole(s) are ON (can be multi-bit)
  input  logic [N_MOLES-1:0]   btn_edge,        // debounced rising-edge pulses (one-hot or multi)
  output logic                 armed,           // level: waiting for hits in the current window
  output logic                 hit_pulse,       // 1 cycle whenever a correct new hit occurs
  output logic                 double_hit_pulse,// 1 cycle when >=2 correct hits in same window
  output logic                 miss_pulse,      // 1 cycle when the window ends with misses
  output logic [N_MOLES-1:0]   moles_hit        // which specific moles were hit this cycle
);

  // State machine states
  typedef enum logic [1:0] { 
    IDLE = 2'b00,   // Waiting for new moles to appear
    ARMED = 2'b01,  // Moles are active, waiting for hits
    DONE = 2'b10    // Window finished, generate final pulses
  } state_t;
  
  state_t current_state, next_state;
  
  // Internal registers
  logic [N_MOLES-1:0] remaining_moles;      // Moles still waiting to be hit
  logic [N_MOLES-1:0] hits_in_window;       // All moles hit during this window
  logic [3:0] hit_count;                    // Count of moles hit in window
  
  // Combinational logic for current cycle hits
  logic [N_MOLES-1:0] valid_hits_now;
  assign valid_hits_now = btn_edge & remaining_moles;  // Only count hits on active moles
  
  // Count how many moles have been hit in total during this window
  always_comb begin
    hit_count = 4'b0;
    for (int i = 0; i < N_MOLES; i++) begin
      if (hits_in_window[i]) hit_count = hit_count + 1'b1;
    end
  end
  
  // Determine what ends the current window
  logic window_complete, window_timeout;
  assign window_complete = (remaining_moles & ~btn_edge) == '0;  // All moles will be hit this cycle
  assign window_timeout = LED_toggle || (active_onehot == '0);   // Timer timeout or moles disappeared
  
  // State machine next state logic
  always_comb begin
    next_state = current_state;
    
    case (current_state)
      IDLE: begin
        if (active_onehot != '0) begin
          next_state = ARMED;  // New moles appeared, start window
        end
      end
      
      ARMED: begin
        if (valid_hits_now != '0 && window_complete) begin
          next_state = DONE;   // Successfully hit all moles
        end
        else if (window_timeout) begin
          next_state = DONE;   // Window ended due to timeout
        end
      end
      
      DONE: begin
        next_state = IDLE;     // Always return to idle after one cycle
      end
      
      default: next_state = IDLE;
    endcase
  end
  
  // Sequential logic
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      current_state <= IDLE;
      remaining_moles <= '0;
      hits_in_window <= '0;
      hit_pulse <= 1'b0;
      double_hit_pulse <= 1'b0;
      miss_pulse <= 1'b0;
    end
    else begin
      current_state <= next_state;
      
      case (current_state)
        IDLE: begin
          if (next_state == ARMED) begin
            // Starting new window - initialize tracking
            remaining_moles <= active_onehot;
            hits_in_window <= '0;
          end
          // Clear all pulses when idle
          hit_pulse <= 1'b0;
          double_hit_pulse <= 1'b0;
          miss_pulse <= 1'b0;
        end
        
        ARMED: begin
          // Update tracking when hits occur
          if (valid_hits_now != '0) begin
            remaining_moles <= remaining_moles & ~btn_edge;  // Remove hit moles
            hits_in_window <= hits_in_window | valid_hits_now;  // Add to hit record
            hit_pulse <= 1'b1;  // Generate hit pulse
          end
          else begin
            hit_pulse <= 1'b0;  // No hits this cycle
          end
          
          // Clear other pulses during armed state
          double_hit_pulse <= 1'b0;
          miss_pulse <= 1'b0;
        end
        
        DONE: begin
          // Generate final pulses based on window outcome
          hit_pulse <= 1'b0;  // No more hit pulses
          
          // Double hit: successful completion with 2+ hits
          if ((remaining_moles == '0) && (hit_count >= 4'd2)) begin
            double_hit_pulse <= 1'b1;
          end
          else begin
            double_hit_pulse <= 1'b0;
          end
          
          // Miss: window ended with moles remaining
          if (remaining_moles != '0) begin
            miss_pulse <= 1'b1;
          end
          else begin
            miss_pulse <= 1'b0;
          end
        end
        
        default: begin
          hit_pulse <= 1'b0;
          double_hit_pulse <= 1'b0;
          miss_pulse <= 1'b0;
        end
      endcase
    end
  end
  
  // Output assignments
  assign armed = (current_state == ARMED);
  assign moles_hit = (current_state == ARMED) ? valid_hits_now : '0;
  
endmodule



//module mole_detector #(
//  parameter int N_MOLES = 10
//)(
//  input  logic                 clk, rst,
//  input  logic                 LED_toggle,      // Pulse from timer - defines mole window
//  input  logic [N_MOLES-1:0]   active_onehot,   // which LED/mole is ON
//  input  logic [N_MOLES-1:0]   btn_edge,        // debounced rising-edge pulses
//  output logic                 armed,           // level: waiting for a hit
//  output logic                 hit_pulse,       // 1 cycle when correct hit
// 
//  output logic                 miss_pulse       // 1 cycle when mole window expires
//);
//  // ---------- state machine ----------
//  typedef enum logic [1:0] { IDLE, ARMED, DONE } state_t;
//  state_t state, next;
//  
//  // Store which mole(s) we're currently tracking
//  logic [N_MOLES-1:0] tracked_mole;
//  
//  // match / non-match - use tracked_mole for consistency
//  logic correct_press;
//  assign correct_press = |(btn_edge & tracked_mole); // Check against tracked moles
//  
//  // miss condition - LED_toggle pulse while still armed means time's up
//  logic timeout_miss, disappeared_miss;
//  assign timeout_miss = LED_toggle && (state == ARMED);  // LED_toggle pulse = window expired
//  assign disappeared_miss = (tracked_mole != '0) && (active_onehot == '0);
//  
//  // level-style output straight from the state
//  assign armed = (state == ARMED);
//  
//  // next-state (combinational)
//  always_comb begin
//    next = state;
//    unique case (state)
//      IDLE  : if (active_onehot != '0)           next = ARMED;         // a mole lit
//      ARMED : if (correct_press)                 next = DONE;          // hit
//              else if (timeout_miss || disappeared_miss)  
//                                                 next = DONE;          // timeout or mole disappeared
//      DONE  : next = IDLE;                       // Always go back to IDLE after one cycle
//    endcase
//  end
//  
//  // sequential: state, pulses, and tracked mole
//  always_ff @(posedge clk or posedge rst) begin
//    if (rst) begin
//      state        <= IDLE;
//      hit_pulse    <= 1'b0;
//      miss_pulse   <= 1'b0;
//      tracked_mole <= '0;
//    end else begin
//      state <= next;
//		
//		// Track multiple moles
//		if (next == ARMED && state == IDLE) begin
//		  tracked_mole <= active_onehot;             // Latch all new moles when entering armed
//		end else if (state == ARMED) begin
//		
//		  // Clear any mole that got hit
//		  tracked_mole <= tracked_mole & ~btn_edge;	
//		  
//		end else if (next == IDLE) begin
//		  tracked_mole <= '0;                        // Clear tracking when going to IDLE
//		end
//
//		// Pulse logic
//		hit_pulse  <= (state == ARMED) && (|(btn_edge & tracked_mole));
//		miss_pulse <= (state == ARMED) && timeout_miss && (tracked_mole != '0);
//					
//			
//			
//			
//			// Past Single mole detection logic:
//			
////      // Track which mole we're currently watching
////      if (next == ARMED && state == IDLE) begin
////        tracked_mole <= active_onehot;  // Latch the mole when entering ARMED
////      end else if (next == IDLE) begin
////        tracked_mole <= '0;             // Clear tracking when going to IDLE
////      end
////      
////      // 1-cycle pulses when transitioning out of ARMED
////      hit_pulse  <= (state == ARMED) && (next == DONE) && correct_press;
////      miss_pulse <= (state == ARMED) && (next == DONE) && !correct_press;
//    end
//  end
//endmodule