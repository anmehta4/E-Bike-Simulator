module nonoverlap(highOut, lowOut, highIn, lowIn, clk, rst_n);

input clk;
input rst_n;
input highIn;
input lowIn;

output logic highOut;
output logic lowOut;

logic highIn_ff1;
logic lowIn_ff1;
logic changed;
logic [4:0] deadtime;

/************************************************
 * Flip Flops to control the outputs for High and Low
 ************************************************/
always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n) begin
     highOut <= 1'b0;
     lowOut <= 1'b0;
   //If either signal has changed we want to force outputs to low for the next 32 clk cycles
   end else if (changed) begin 
     highOut <= 1'b0;
     lowOut <= 1'b0;
   //If 32 clk cycles deadtime is complete, we let the input signals drive the output signals
   end else if(&deadtime) begin
     highOut <= highIn;
     lowOut <= lowIn;
   end 
end

always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n) begin
     deadtime <= '1;
   //If either signal has changed we want to restart counting 32 clk cycles deadtime
   end else if (changed) begin
     deadtime <= 5'b0;
   end else if (deadtime != '1)
     deadtime <= deadtime + 5'b1;
end

/***********************************************
 * Flop to keep track of the previous and current values
 * to ensure that inputs have not changed
 ************************************************/
always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n) begin
      highIn_ff1 <= '0;
      lowIn_ff1 <= '0;
   end else begin
      highIn_ff1 <= highIn;
      lowIn_ff1 <= lowIn;
   end
end

//Logic to compare previous and current inputs and make sure they're equals
always_comb begin
   changed = (lowIn_ff1 != lowIn) || (highIn_ff1 != highIn);
end
  
endmodule
