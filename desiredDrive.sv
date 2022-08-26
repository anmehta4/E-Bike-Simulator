module desiredDrive( clk, avg_torque,	
			cadence, 
			not_pedaling, 
			incline, 
			scale, 
			target_curr);

input clk;
input [11:0] avg_torque;
input [4:0] cadence;
input not_pedaling;
input signed [12:0] incline;
input [2:0] scale;
output [11:0] target_curr;

localparam TORQUE_MIN = 12'h380;
localparam signed FACTOR = 11'd256;
reg signed [9:0] incline_sat;
logic signed [10:0] incline_factor, incline_factor_ff1;
logic [2:0] scale_ff1;
logic [8:0] incline_lim, incline_lim_ff1;
wire [12:0] torque_off;
logic [12:0] torque_pos, torque_pos_ff1;
logic [18:0] prod1;
logic [27:0] prod2;
logic [29:0] prod3;
logic [29:0] assist_prod, assist_prod_ff1;
wire [6:0] cadence_sum;
logic [5:0] cadence_factor, cadence_factor_ff1;

always_ff @ (posedge clk) begin
   scale_ff1 <= scale;
end

//Saturating the incline from 13 to 10 bits
assign incline_sat =  (!incline[12] && |incline[11:9]) ? 10'h1FF :
		      ( incline[12] && !(&incline[11:9])) ? 10'h200 :
		      (incline[9:0]);

//Creating a sign extended 11-bit incline_factor by adding 256
assign incline_factor = incline_sat + FACTOR;

always_ff @ (posedge clk) begin
   incline_factor_ff1 <= incline_factor;
end

//create a new 9-bit saturated signal that is clipped w.r.t negative values
assign incline_lim =  (!incline_factor_ff1[10] && incline_factor_ff1[9]) ? 9'h1FF :
		      (incline_factor_ff1[10]) ? 9'h000 :
		      (incline_factor_ff1[8:0]);

always_ff @ (posedge clk) begin
   incline_lim_ff1 <= incline_lim;
end

//unsigned force of pedaline after subtracting offset
assign torque_off = {1'b0, avg_torque} - {1'b0, TORQUE_MIN};

//create a new 12-bit saturated signal that is clipped w.r.t negative values
assign torque_pos = torque_off[12] ?  12'b0 : torque_off[11:0];

always_ff @ (posedge clk) begin
   torque_pos_ff1 <= torque_pos;
end

//Adding 32 for cadence to ne used if greater than 1
assign cadence_sum = cadence + 6'd32;

assign cadence_factor = (|cadence[4:1]) ? cadence_sum : 6'b0;

always_ff @ (posedge clk) begin
   cadence_factor_ff1 <= cadence_factor;
end

//partitioning multiplication
always_ff @ (posedge clk) begin
   prod1 <= torque_pos_ff1 * cadence_factor_ff1;
   prod2 <= prod1 * incline_lim_ff1;
   prod3 <= prod2 * scale_ff1;
end

//creating a product for the assist_prod
assign assist_prod = not_pedaling ? 30'h0000_0000 : (prod3);

always_ff @ (posedge clk) begin
   assist_prod_ff1 <= assist_prod;
end

//extracting target current based on 3 MSB
assign target_curr = (|assist_prod_ff1[29:27]) ? 12'hFFF : assist_prod_ff1[26:15];

endmodule

