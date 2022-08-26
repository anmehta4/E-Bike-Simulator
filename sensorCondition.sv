module sensorCondition(clk, rst_n, torque, cadence_raw, curr, incline,
                       scale, batt, error, not_pedaling, TX);

parameter FAST_SIM = 0;

localparam LOW_BATT_THRES = 12'hA98;

input clk, rst_n;
input cadence_raw;
input [2:0] scale;
input [12:0] incline;
input [11:0] curr, torque, batt;
output logic [12:0] error;
output logic TX, not_pedaling;


logic [21:0] counter;
logic include_sample;
logic pedaling_resumes, not_pedaling_ff1;

logic [11:0] avg_curr, target_curr, sub_curr;
logic [13:0] accum_curr, sum_curr, mux_curr;
logic [15:0] mult_curr;

logic [11:0] avg_torque;
logic [16:0] accum_torque, sum_torque, mux_torque, mux1_torque;
logic [21:0] mult_torque;

logic [12:0] error_curr; 
logic cadence_filt, cadence_rise;
logic [7:0] cadence_per;
logic [4:0] cadence;


cadence_filt #(.FAST_SIM(FAST_SIM)) cadence_filter(.cadence_rise(cadence_rise), .cadence_filt(cadence_filt), .cadence(cadence_raw),
			    .clk(clk), .rst_n(rst_n));
cadence_meas #(.FAST_SIM(FAST_SIM)) cadence_meas(.clk(clk), .rst_n(rst_n), .cadence_filt(cadence_filt), .cadence_per(cadence_per), 
			  .not_pedaling(not_pedaling));
cadence_LU cadence_LU(.cadence_per(cadence_per), .cadence(cadence));

desiredDrive desiredDrive(.clk(clk), .avg_torque(avg_torque), .cadence(cadence), .not_pedaling(not_pedaling), 
			  .incline(incline), .scale(scale), .target_curr(target_curr));
telemetry telemetry(.clk(clk), .rst_n(rst_n), .batt_v(batt), .avg_curr(avg_curr), .avg_torque(avg_torque), .TX(TX));



always_ff @ (posedge clk, negedge rst_n) begin
   if(!rst_n) 
       not_pedaling_ff1 <= 1'b0;
   else
       not_pedaling_ff1 <= not_pedaling;
end

assign pedaling_resumes = not_pedaling_ff1 & ~not_pedaling;

always_ff @ (posedge clk, negedge rst_n) begin
  if(!rst_n)
     counter <= 22'd0;
  else
     counter <= counter + 22'd1;
end

always_ff @ (posedge clk, negedge rst_n) begin
  if(!rst_n)
     accum_curr <= 13'b0;
  else
     accum_curr <= mux_curr;
end

assign mult_curr = accum_curr * 2'd3;//{accum_curr[13:4], 4'h0} - accum_curr;
assign sum_curr = mult_curr[15:2] + curr;
assign mux_curr = include_sample ? sum_curr : accum_curr;
assign avg_curr = accum_curr[13:2];

always_ff @ (posedge clk, negedge rst_n) begin
  if(!rst_n)
     accum_torque <= 22'b0;
  else
     accum_torque <= mux_torque;
end

assign mult_torque = accum_torque * 5'd31;//{accum_torque[16:4], 4'h0} - accum_torque;
assign sum_torque = mult_torque[21:5] + torque;
assign mux1_torque = cadence_rise ? sum_torque : accum_torque;
assign mux_torque = pedaling_resumes ? {1'b0, torque, 4'h0} : mux1_torque;
assign avg_torque = accum_torque[16:5];

assign sub_curr = target_curr - avg_curr;
assign error_curr = {sub_curr[11], sub_curr};
assign error = (not_pedaling | (batt < LOW_BATT_THRES)) ? 13'b0 : error_curr;

/////////////////////////////////////////////////////////////
// FAST_SIM code
/////////////////////////////////////////////////////////////
generate if(FAST_SIM)
   assign include_sample = &counter[15:0];
else
   assign include_sample = &counter[21:0];
endgenerate

endmodule
