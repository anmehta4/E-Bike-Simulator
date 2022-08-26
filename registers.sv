module registers(clk, rst_n, control_sig, 
 		 resp, roll_rt, yaw_rt, AY, AZ);


input clk, rst_n;
input [7:0] control_sig;
input [15:0] resp;

output reg [15:0] roll_rt, yaw_rt, AY, AZ;

//logic [7:0] control_sig = {C_R_L, C_R_H, C_Y_L, C_Y_H, C_AY_L, C_AY_H, C_AZ_L, C_AZ_H};

always_ff @(posedge clk) begin
   case(control_sig)
 	8'b10000000: roll_rt[7:0] <= resp[7:0];
 	8'b01000000: roll_rt[15:8] <= resp[7:0];
 	8'b00100000: yaw_rt[7:0] <= resp[7:0];
 	8'b00010000: yaw_rt[15:8] <= resp[7:0];
 	8'b00001000: AY[7:0] <= resp[7:0];
 	8'b00000100: AY[15:8] <= resp[7:0];
 	8'b00000010: AZ[7:0] <= resp[7:0];
 	8'b00000001: AZ[15:8] <= resp[7:0];
   endcase
end

endmodule