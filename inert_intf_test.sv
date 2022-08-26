module inert_intf_test(RST_n, clk, SS_n, SCLK, MOSI, MISO, INT, LED);

input logic clk, MISO, RST_n;
input logic INT;

output logic SS_n, SCLK, MOSI;
output logic [7:0] LED;

logic vld;
logic rst_n;
logic [12:0] incline;
inert_intf inter_intf(.clk(clk), .rst_n(rst_n), .MISO(MISO), .INT(INT),
		      .incline(incline), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .vld(vld));
reset_synch reset_synch(.clk(clk), .rst_n(rst_n), .RST_n(RST_n));

always_ff @(posedge clk) begin
	if(vld)
		LED <= incline[8:1];
end

endmodule
