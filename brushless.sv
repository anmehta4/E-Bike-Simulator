module brushless(clk, rst_n, drv_mag, hallGrn, hallYlw,	
	 	 hallBlu, brake_n, PWM_synch, duty, selGrn, selYlw, selBlu);

input logic clk, rst_n, brake_n, PWM_synch;
input logic hallGrn, hallYlw, hallBlu;
input logic [11:0] drv_mag;

output logic [10:0] duty;
output logic [1:0] selGrn, selBlu, selYlw;

logic [11:0] drv_mag_ff1;
/***********************************************
 * Double flopping the hall inputs
 ************************************************/
logic hallGrn_1, hallYlw_1, hallBlu_1;
logic hallGrn_2, hallYlw_2, hallBlu_2;

always_ff @ (posedge clk) begin
   hallGrn_1 <= hallGrn;
   hallGrn_2 <= hallGrn_1;

   hallYlw_1 <= hallYlw;
   hallYlw_2 <= hallYlw_1;

   hallBlu_1 <= hallBlu;
   hallBlu_2 <= hallBlu_1;
end

/***********************************************
 * Synch outputs from FFs
 ************************************************/
logic synchGrn, synchYlw, synchBlu;
logic hallGrn_mux, hallYlw_mux, hallBlu_mux;

always_ff @ (posedge clk, negedge rst_n) begin
   if(!rst_n) begin
      synchGrn <= 1'b0;
      synchBlu <= 1'b0;
      synchYlw <= 1'b0;
   end else begin
      synchGrn <= hallGrn_mux;
      synchBlu <= hallBlu_mux;
      synchYlw <= hallYlw_mux;
   end
end

/***********************************************
 * Mux Outputs based on PWM_synch
 ************************************************/
always_comb begin
   if(PWM_synch) begin
      hallGrn_mux = hallGrn_2;
      hallBlu_mux = hallBlu_2;
      hallYlw_mux = hallYlw_2;
   end else begin
      hallGrn_mux = synchGrn;
      hallBlu_mux = synchBlu;
      hallYlw_mux = synchYlw;
   end
end

/***********************************************
 * Drive outputs based on rotation_state
 *************************************************/
logic [2:0] rotation_state;
assign rotation_state = {synchGrn, synchYlw, synchBlu};

always_comb begin
   if(!brake_n) begin
       selGrn = 2'b11; //REGEN
       selYlw = 2'b11; //REGEN
       selBlu = 2'b11; //REGEN
   end else begin
    case(rotation_state) 
      3'b101: begin
	   selGrn = 2'b10; //FWRD
	   selYlw = 2'b01; //REV
	   selBlu = 2'b00; //HIGHZ
      end
      3'b100: begin
	   selGrn = 2'b10; //FWRD
	   selYlw = 2'b00; //HIGHZ
	   selBlu = 2'b01; //REV
      end
      3'b110: begin
	   selGrn = 2'b00; //HIGHZ
	   selYlw = 2'b10; //FWRD
	   selBlu = 2'b01; //REV
      end
      3'b010: begin
	   selGrn = 2'b01; //REV
	   selYlw = 2'b10; //FWRD
	   selBlu = 2'b00; //HIGHZ
      end
      3'b011: begin
	   selGrn = 2'b01; //REV
	   selYlw = 2'b00; //HIGHZ
	   selBlu = 2'b10; //FWRD
      end
      3'b001: begin
	   selGrn = 2'b00; //HIGHZ
	   selYlw = 2'b01; //REV
	   selBlu = 2'b10; //FWRD
      end
      default: begin
	   selGrn = 2'b00; //HIGHZ
	   selYlw = 2'b00; //HIGHZ
	   selBlu = 2'b00; //HIGHZ
      end
     endcase
   end
end

always_ff @ (posedge clk) begin
   drv_mag_ff1 <= drv_mag;
end

/***********************************************
 * Drive outputs duty based on brake_n
 *************************************************/
always_comb begin
   if(brake_n) 
      duty = 11'h400 + drv_mag_ff1[11:2];
   else
      duty = 11'h600;
end

endmodule
