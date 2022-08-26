module SPI_mnrch(clk, rst_n, SS_n, MISO, SCLK, MOSI, snd, cmd, done, resp);

input clk, rst_n, MISO, snd;
input [15:0] cmd;
output logic SS_n, SCLK, MOSI, done;
output logic [15:0] resp;

//State machine outputs
logic init;
logic set_done;
logic ld_SCLK;

/*************************************************
 * SCLK calculator and computation
 ************************************************/
logic full, shft;
logic [4:0] SCLK_div;
logic done16;

always_ff @ (posedge clk) begin
  //If load_SCLK is asserted we assign value of 5'b10111 else increment
  if(ld_SCLK)
    SCLK_div <= 5'b10111;
  else
    SCLK_div <= SCLK_div + 1;
end

always_comb begin
  SCLK = SCLK_div[4];
  //If SCLK_div = 5'b10001, we have encountered a rising edge, therefore begin shift
  if (SCLK_div == 5'b10001)
     shft = 1'b1;
  else 
     shft = 1'b0;
 
  full = &SCLK_div; //If all bits are asserted then we assert full 
end

/*************************************************
 * SHIFT 16 Bits calculator and computation
 ************************************************/
logic [4:0] bit_cntr;

always_ff @ (posedge clk, negedge rst_n) begin

  if(!rst_n)
    bit_cntr <= 5'b00000;
  else if(init) //if init then load value 0
    bit_cntr <= 5'b00000;
  else if(shft) // else we incrememnt counter
    bit_cntr <= bit_cntr + 4'b1;
  //else we maintain the value which is implied
end

//Since we want to count 16 bits it will only be when the most significant bit is asserted
assign done16 = bit_cntr[4]; 

/************************************************
 * Shifting the value from MISO to MOSI
 ***********************************************/
logic [15:0] shft_reg;
logic [15:0] mux_out;

always_comb begin
  if ({init, shft} == 2'b01)
    mux_out = {shft_reg[14:0], MISO};
  else if ({init, shft} == 2'b00)
    mux_out = shft_reg;
  else
    mux_out = cmd;
end

always_ff @ (posedge clk) begin
  //MOSI <= shft_reg[15];
  shft_reg <= mux_out;
end

assign MOSI = shft_reg[15];
/**************************************************
 * Controlling the outputs of SS_n and done
 **************************************************/
always_ff @ (posedge clk, negedge rst_n) begin
  if(!rst_n) begin
     done <= 1'b0; //reset
     SS_n <= 1'b1; //preset
  end else if(init) begin
     done <= 1'b0; //if init then not done 
     SS_n <= 1'b0; //deassert SS_n to begin 
  end else if (set_done) begin
     resp <= shft_reg;
     done <= 1'b1; //if set_done then assert done 
     SS_n <= 1'b1; //assert SS_n to end 
  end else
    done <=1'b0;
end

/****************************************************
 * State Machine
 ****************************************************/
typedef enum reg[1:0] {IDLE=2'b00,SHIFT=2'b01, LAST=2'b10} state_t;
state_t nxt_state;
logic [2:0] state;

	
always_comb begin
  /////////////////////////////////////////
  // Default all SM outputs & nxt_state //
  ///////////////////////////////////////
  ld_SCLK = 1'b1;
  set_done = 1'b0;
  init = 1'b0;
  nxt_state = state_t'(state);
		
  //state transition logic and output logic
  case (state)
    IDLE: begin
	//Starting shifting and assert init signal to start counting
	if(snd) begin 
	  nxt_state = SHIFT;
	  init = 1'b1;
	end else begin
	  nxt_state = IDLE;
	end
     end

    SHIFT: begin
	ld_SCLK = 1'b0; //Ensure the SCLK counts and doesn't load value
        if(done16) begin //if 16 bis transmitted then go to next state
	  nxt_state = LAST;
	end else begin
	  nxt_state = SHIFT;
	end 
     end
    LAST: begin
        if(full) begin //After full is asserted go back to idle
          nxt_state = IDLE;
          set_done = 1'b1; //assert set_done because trasnmission done
        end else begin
	  ld_SCLK = 1'b0;
          nxt_state = LAST;
        end
     end
    default: nxt_state = IDLE;
  endcase
end

//Iterate through which state in the machine
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= 2'b00;
  else
    state <= nxt_state;
end

endmodule
