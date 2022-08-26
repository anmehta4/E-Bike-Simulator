module reset_synch (clk, rst_n, RST_n);

input clk;
input RST_n;
output logic rst_n;

logic ff_1;

always_ff @ (negedge clk, negedge RST_n) begin

   if(!RST_n) begin
       ff_1 <= 1'b0;
       rst_n <= 1'b0;
   end else begin
       ff_1 <= 1'b1;
       rst_n <= ff_1;
   end
end

endmodule
