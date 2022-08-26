module PB_intf (clk, rst_n, tgglMd, scale, setting);

input clk;
input rst_n;
input tgglMd;
output logic [1:0] setting;
output logic [2:0] scale;

logic tggl_ff1, tggl_ff2, tggl_ff3;
logic rise_edge;
logic [1:0] counter;

always_ff @ (posedge clk, negedge rst_n) begin
   if(!rst_n) begin
       tggl_ff1 <= 1'b0;
       tggl_ff2 <= 1'b0;
       tggl_ff3 <= 1'b0;
   end else begin
       tggl_ff1 <= tgglMd;
       tggl_ff2 <= tggl_ff1;
       tggl_ff3 <= tggl_ff2;
   end
end

always_ff @ (posedge clk, negedge rst_n) begin
   if(!rst_n) 
       counter <= 2'b01;
   else if(rise_edge) 
       counter <= counter + 2'b01;
end

assign rise_edge = tggl_ff2 & ~tggl_ff3;
assign setting = counter;

always_comb begin
   case(setting)
       2'b00: scale = 3'b000;
       2'b01: scale = 3'b011;
       2'b10: scale = 3'b101;
       2'b11: scale = 3'b111;
   endcase
end

endmodule
