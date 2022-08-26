module PWM(duty, PWM_sig, PWM_synch, clk, rst_n);

input clk;
input rst_n;
input [10:0] duty;
output reg PWM_sig;
output reg PWM_synch;

logic cnt_lt_duty;
logic [10:0] cnt;

/*********************************************
 * FF to assign the output of PWM_sig every posedge of clk
 **********************************************/
always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n)
     PWM_sig <= 1'b0;
   else
     PWM_sig <= cnt_lt_duty;
end

/*********************************************
 * FF to keep count of the clock cycles ~2048
 **********************************************/
always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n)
     cnt <= 11'b0;
   else
     cnt <= cnt + 1; //Count incrementer
end

always_comb begin

   //If count is less than equal the duty cycle we output 1 else 0
   if (cnt <= duty)
     cnt_lt_duty = 1'b1;
   else  
     cnt_lt_duty = 1'b0;
 
   //If count == 11'b1 we assert PWM_synch else we deassert it
   if (cnt == 11'b1)
     PWM_synch = 1'b1;
   else  
     PWM_synch = 1'b0;

end

endmodule
