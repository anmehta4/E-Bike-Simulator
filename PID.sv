module PID (clk, rst_n, error, not_pedaling, drv_mag);
parameter FAST_SIM = 0;

input logic clk, rst_n, not_pedaling;
input logic signed [12:0] error;
output logic [11:0] drv_mag;

logic signed [13:0] P_term; 
/////////////////////////////////////////////////////////////
// P_Term (just sign extending)
/////////////////////////////////////////////////////////////
assign P_term = {error[12],error};

logic signed [12:0] error_ff1, error_ff2, error_ff3;
always @(posedge clk) begin
   error_ff1 <= error;
   error_ff2 <= error_ff1;
   error_ff3 <= error_ff2;
end

logic [17:0] integrator, adder, I_mux1, I_mux2, I_mux3, I_mux4;
logic [19:0] decimator;
logic pos_ov, decimator_full;
logic [11:0] I_term;
/////////////////////////////////////////////////////////////
// I_term
/////////////////////////////////////////////////////////////

always_ff @ (posedge clk, negedge rst_n) begin
   if(!rst_n)
      integrator <= 18'h00000;
   else
      integrator <= I_mux4;
end

/********************************************
 * Decimator counter - 20 bit counter
 ********************************************/
always_ff @ (posedge clk, negedge rst_n) begin
   if(!rst_n)
      decimator <= 20'b00000;
   else
      decimator <= decimator + 20'b1;
end
   
assign adder = {{5{error_ff1[12]}}, error_ff1} + integrator;
assign pos_ov = integrator[16] & adder[17];

assign I_mux1 = adder[17] ? 18'h00000 : adder;
assign I_mux2 = pos_ov ? 18'h1FFFF : I_mux1;
assign I_mux3 = decimator_full ? I_mux2 : integrator;
assign I_mux4 = not_pedaling ? 18'h00000: I_mux3;

assign I_term = integrator[16:5];


logic signed [12:0] D_mux1, D_mux2, D_mux3;
logic signed [12:0] D_ff1, D_ff2, D_ff3;
logic signed [12:0] D_diff, D_sat;
logic signed [9:0] D_term;
/////////////////////////////////////////////////////////////
// D_term
/////////////////////////////////////////////////////////////

/************************************************
 * 3 Flops to flop the signal 3 times in ordet to obtain
 * error and prev_error which is 2 time units ago
 ************************************************/
always_ff @ (posedge clk, negedge rst_n) begin
   if(!rst_n)
      D_ff1 <= 13'b0000;
   else
      D_ff1 <= D_mux1;
end

always_ff @ (posedge clk, negedge rst_n) begin
   if(!rst_n)
      D_ff2 <= 13'b0000;
   else
      D_ff2 <= D_mux2;
end

always_ff @ (posedge clk, negedge rst_n) begin
   if(!rst_n)
      D_ff3 <= 13'b0000;
   else
      D_ff3 <= D_mux3;
end


//mux to determine inputs to flop the signal 3 times to get error and error 2 time units ago
assign D_mux1 = decimator_full ? error : D_ff1;
assign D_mux2 = decimator_full ? D_ff1 : D_ff2;
assign D_mux3 = decimator_full ? D_ff2 : D_ff3;

assign D_diff = error_ff3 - D_ff3; // Error - prev_error
//Saturate the difference
assign D_sat = (!D_diff[12] && |D_diff[11:8]) ? 9'h0FF :
	       (D_diff[12] && !(&D_diff[11:8])) ? 9'h100 :
	       (D_diff[8:0]);
assign D_term = {D_sat, 1'b0}; //multiplication by 2 which is shift left by 1 bit

/////////////////////////////////////////////////////////////
// Final Computation: PID = P + I + D
/////////////////////////////////////////////////////////////
logic signed [13:0] P_term_final, D_term_final, PID;
logic [13:0] I_term_final;
logic [11:0] drv_mag_mux1;

assign P_term_final = P_term;
assign I_term_final = {2'b00, I_term};
assign D_term_final = {{4{D_term[9]}}, D_term};
assign PID = P_term_final + I_term_final + D_term_final;

/**********************************************************
 * Overflow handling and final output
 **********************************************************/
assign drv_mag_mux1 = PID[12] ? 12'hFFF : PID[11:0];
assign drv_mag = PID[13] ? 12'h000 : drv_mag_mux1;

/////////////////////////////////////////////////////////////
// FAST_SIM code
/////////////////////////////////////////////////////////////
generate if(FAST_SIM)
   assign decimator_full = &decimator[14:0];
else
   assign decimator_full = &decimator;
endgenerate

endmodule
