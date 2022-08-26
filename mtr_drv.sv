module mtr_drv(clk, rst_n, selGrn, selYlw, selBlu, duty, PWM_synch,
	       highGrn, lowGrn, highBlu, lowBlu, highYlw, lowYlw);

input logic clk, rst_n;
input logic [10:0] duty;
input logic [1:0] selGrn, selBlu, selYlw;

output logic highGrn, lowGrn, highBlu, lowBlu, highYlw, lowYlw, PWM_synch;

logic PWM_sig;
PWM PWMi(.duty(duty), .PWM_sig(PWM_sig), .PWM_synch(PWM_synch), .clk(clk), .rst_n(rst_n));

logic highGrn_i, lowGrn_i, highBlu_i, lowBlu_i, highYlw_i, lowYlw_i;

nonoverlap nonoverlapGrn(.highOut(highGrn), .lowOut(lowGrn), .highIn(highGrn_i),
			 .lowIn(lowGrn_i), .clk(clk), .rst_n(rst_n));
nonoverlap nonoverlapYlw(.highOut(highYlw), .lowOut(lowYlw), .highIn(highYlw_i),
			 .lowIn(lowYlw_i), .clk(clk), .rst_n(rst_n));
nonoverlap nonoverlapBlu(.highOut(highBlu), .lowOut(lowBlu), .highIn(highBlu_i),
			 .lowIn(lowBlu_i), .clk(clk), .rst_n(rst_n));

always_comb begin

   case(selGrn) 
      2'b00: begin
	 highGrn_i = 1'b0;
	 lowGrn_i = 1'b0;
      end
      2'b01: begin
	 highGrn_i = ~PWM_sig;
	 lowGrn_i = PWM_sig;
      end
      2'b10: begin
	 highGrn_i = PWM_sig;
	 lowGrn_i = ~PWM_sig;
      end
      2'b11: begin
	 highGrn_i = 1'b0;
	 lowGrn_i = PWM_sig;
      end
   endcase

   case(selYlw) 
      2'b00: begin
	 highYlw_i = 1'b0;
	 lowYlw_i = 1'b0;
      end
      2'b01: begin
	 highYlw_i = ~PWM_sig;
	 lowYlw_i = PWM_sig;
      end
      2'b10: begin
	 highYlw_i = PWM_sig;
	 lowYlw_i = ~PWM_sig;
      end
      2'b11: begin
	 highYlw_i = 1'b0;
	 lowYlw_i = PWM_sig;
      end
   endcase

   case(selBlu) 
      2'b00: begin
	 highBlu_i = 1'b0;
	 lowBlu_i = 1'b0;
      end
      2'b01: begin
	 highBlu_i = ~PWM_sig;
	 lowBlu_i = PWM_sig;
      end
      2'b10: begin
	 highBlu_i = PWM_sig;
	 lowBlu_i = ~PWM_sig;
      end
      2'b11: begin
	 highBlu_i = 1'b0;
	 lowBlu_i = PWM_sig;
      end
   endcase
end

endmodule
