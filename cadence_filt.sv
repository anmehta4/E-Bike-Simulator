module cadence_filt(cadence_filt, cadence_rise, cadence, clk, rst_n);

parameter FAST_SIM = 0;

input clk;
input rst_n;
input cadence;
output logic cadence_filt;
output logic cadence_rise;

logic cadence_ff1, cadence_ff2, cadence_ff3;
logic [15:0] stbl_cnt;
logic [15:0] d_hat;
logic stable;
logic chngd_n;
logic d;

always_ff @ (posedge clk, negedge rst_n) begin
   if(!rst_n) begin
      cadence_ff1 <= 1'b0;
      cadence_ff2 <= 1'b0;
      cadence_ff3 <= 1'b0;
   end else begin
      cadence_ff1 <= cadence;
      cadence_ff2 <= cadence_ff1;
      cadence_ff3 <= cadence_ff2;
   end
end

always_ff @ (posedge clk, negedge rst_n) begin
  if(!rst_n)
     stbl_cnt <= 16'b0;
  else
     stbl_cnt <= d_hat + 16'b1;
end

always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
     cadence_filt <= 1'b0;
  else
     cadence_filt <= d;
end

//Creating chngd_n for the counter
assign chngd_n = ~(cadence_ff3 ^ cadence_ff2);

//Anding gate to direct correct input to adder FF
assign d_hat = {16{chngd_n}} & stbl_cnt;

/* Ensuring stable only when stbl_cnt = 65535 which is closest to 50000
 * 50MHz = 0.00002 ms, Stable atleast 1ms implies atleast 1/0.00002 = 50000 clock cycles
 * Hence 16 bits = 65535
 */
//assign stable = &stbl_cnt;

//directing output based on stable or not
assign d = stable ? cadence_ff3 : cadence_filt;

assign cadence_rise = ~cadence_ff3 & cadence_ff2;
/////////////////////////////////////////////////////////////
// FAST_SIM code
/////////////////////////////////////////////////////////////
generate if(FAST_SIM)
   assign stable = &stbl_cnt[8:0];
else
   assign stable = &stbl_cnt[15:0];
endgenerate

endmodule
