module cadence_meas(clk, rst_n, cadence_filt, cadence_per, not_pedaling);

parameter FAST_SIM = 0;

localparam THIRD_SEC_REAL = 24'hE4E1C0;
localparam THIRD_SEC_FAST = 24'h007271;
localparam THIRD_SEC_UPPER = 8'hE4;

input logic clk, rst_n;
input logic cadence_filt;

output logic [7:0] cadence_per;
output logic not_pedaling;

logic [23:0] THIRD_SEC;
logic cadence_filt_ff1;
logic cadence_rise, sel_mux1, capture_per;
logic [23:0] mux1_out, mux2_out, ff1_out;
logic [7:0] mux3_out, mux4_out, mux5_out;

always_ff @ (posedge clk, negedge rst_n) begin
   if(!rst_n) 
       cadence_filt_ff1 <= 1'b0;
   else
       cadence_filt_ff1 <= cadence_filt;
end

always_ff @ (posedge clk, negedge rst_n) begin
   if(!rst_n) 
       ff1_out <= 24'h000000;
   else
       ff1_out <= mux2_out;
end

always_ff @ (posedge clk) begin
    cadence_per <= mux5_out;
end

assign cadence_rise = ~cadence_filt_ff1 & cadence_filt;
assign sel_mux1 = (ff1_out == THIRD_SEC);
assign capture_per = (sel_mux1 | cadence_rise);

assign mux1_out = sel_mux1 ? ff1_out : (ff1_out + 1'd1);
assign mux2_out = cadence_rise ? 24'h000000 : mux1_out;
assign mux3_out = FAST_SIM ? ff1_out[14:7] : ff1_out[23:16];
assign mux4_out = capture_per ? mux3_out : cadence_per;
assign mux5_out = rst_n ? mux4_out : THIRD_SEC_UPPER;

assign not_pedaling = (cadence_per == THIRD_SEC_UPPER);

/////////////////////////////////////////////////////////////
// FAST_SIM code
/////////////////////////////////////////////////////////////
generate if(FAST_SIM)
   assign THIRD_SEC = THIRD_SEC_FAST;
else
   assign THIRD_SEC = THIRD_SEC_REAL;
endgenerate

endmodule
