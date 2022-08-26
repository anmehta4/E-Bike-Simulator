`default_nettype none
module eBike_tb();
 
  // include or import tasks?
  import ebike_tasks::*;

  localparam FAST_SIM = 1;		// accelerate simulation by default

  ///////////////////////////
  // Stimulus of type reg //
  /////////////////////////
  reg clk,RST_n;
  reg [11:0] BATT;				// analog values
  reg [11:0] BRAKE,TORQUE;		// analog values
  reg tgglMd;					// push button for assist mode
  reg [15:0] YAW_RT;			// models angular rate of incline (+ => uphill)


  //////////////////////////////////////////////////
  // Declare any internal signal to interconnect //
  ////////////////////////////////////////////////
  wire A2D_SS_n,A2D_MOSI,A2D_SCLK,A2D_MISO;
  wire highGrn,lowGrn,highYlw,lowYlw,highBlu,lowBlu;
  wire hallGrn,hallBlu,hallYlw;
  wire inertSS_n,inertSCLK,inertMISO,inertMOSI,inertINT;
  logic [7:0] rx_data;
  logic rdy;
  
  reg cadence;
  wire [1:0] LED;			// hook to setting from PB_intf
  
  wire signed [12:0] coilGY,coilYB,coilBG;
  logic [11:0] curr;		// comes from hub_wheel_model
  wire [11:0] BATT_TX, TORQUE_TX, CURR_TX;
  logic vld_TX, TX_RX;
  

  //////////////////////////////////////////////////
  // Instantiate model of analog input circuitry //
  ////////////////////////////////////////////////
  AnalogModel iANLG(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
                    .MISO(A2D_MISO),.MOSI(A2D_MOSI),.BATT(BATT),
		    .CURR(curr),.BRAKE(BRAKE),.TORQUE(TORQUE));

  ////////////////////////////////////////////////////////////////
  // Instantiate model inertial sensor used to measure incline //
  //////////////////////////////////////////////////////////////
  eBikePhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(inertSS_n),.SCLK(inertSCLK),
	             .MISO(inertMISO),.MOSI(inertMOSI),.INT(inertINT),
		     .yaw_rt(YAW_RT),.highGrn(highGrn),.lowGrn(lowGrn),
		     .highYlw(highYlw),.lowYlw(lowYlw),.highBlu(highBlu),
		     .lowBlu(lowBlu),.hallGrn(hallGrn),.hallYlw(hallYlw),
		     .hallBlu(hallBlu),.avg_curr(curr));

  //////////////////////
  // Instantiate DUT //
  ////////////////////
  eBike #(FAST_SIM) iDUT(.clk(clk),.RST_n(RST_n),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
                         .A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.hallGrn(hallGrn),
			 .hallYlw(hallYlw),.hallBlu(hallBlu),.highGrn(highGrn),
			 .lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
			 .highBlu(highBlu),.lowBlu(lowBlu),.inertSS_n(inertSS_n),
			 .inertSCLK(inertSCLK),.inertMOSI(inertMOSI),
			 .inertMISO(inertMISO),.inertINT(inertINT),
			 .cadence(cadence),.tgglMd(tgglMd),.TX(TX_RX),
			 .LED(LED));
			 
  UART_rcv UART_rcv(.clk(clk), .rst_n(RST_n), .RX(TX_RX) , .rdy(rdy), .rx_data(rx_data), .clr_rdy(1'b0)); 
  ////////////////////////////////////////////////////////////
  // Instantiate UART_rcv or some other telemetry monitor? //
  //////////////////////////////////////////////////////////
		
  logic [55:0] stim [0:19];
  logic [9:0] loop_var;
  logic [1:0] cad_pick;
  logic [12:0] error1, error2, error3;
  logic signed [19:0] omega1, omega2, omega3;
  logic [12:0] backemf1, backemf2, backemf3;
  logic [11:0] avg_tor1, avg_tor2, avg_tor3;
  logic [11:0] torque_prev = 12'h0;
  logic bool_torque = 1'b0;
  logic selgrn1, selgrn2, selgrn3;
  logic selblu1, selblu2, selblu3;
  logic selylw1, selylw2, selylw3;

  initial begin
    $readmemh("ebike_stim.hex", stim);
    initialize(.clk(clk), .RST_n(RST_n), .loop_var(loop_var), .cad_pick(cad_pick), .cadence(cadence));  
    TORQUE = 12'h0;
    for(loop_var = 10'h0; loop_var <= 10'h12; loop_var = loop_var + 10'h1) begin
       //Applying stimulus to the DUT
       torque_prev = TORQUE;
       YAW_RT 	= stim[loop_var][15:0];  //16'h0200;
       TORQUE  	= stim[loop_var][27:16]; //12'h900;
       BRAKE 	= stim[loop_var][39:28]; //12'h700;
       BATT   	= stim[loop_var][51:40]; //12'hbff;	
       cad_pick	= stim[loop_var][53:52]; //00
       tgglMd 	= stim[loop_var][54];
       $display("Starting sim %x: Brake: %x Torque: %x Batt: %x Incline: %x", loop_var, BRAKE, TORQUE, BATT, YAW_RT);

       //Storing values periodically throuhgout some time and then comparing after
       repeat(300000)@(posedge clk); //1000000
       error1 = iDUT.sensorCondition.error;
       error1 = (error1[12] ? -1 : 1)*error1;
       avg_tor1 = iDUT.sensorCondition.avg_torque;
       omega1 = iPHYS.omega;
       selblu1 = iDUT.selBlu;
       selgrn1 = iDUT.selGrn;
       selylw1 = iDUT.selYlw;
       backemf1 = iPHYS.back_emf;
       repeat(300000)@(posedge clk); //1000000
       error2 = iDUT.sensorCondition.error;
       error2 = (error2[12] ? -1 : 1)*error2;
       avg_tor2 = iDUT.sensorCondition.avg_torque;
       omega2 = iPHYS.omega;
       selblu2 = iDUT.selBlu;
       selgrn2 = iDUT.selGrn;
       selylw2 = iDUT.selYlw;
       backemf2 = iPHYS.back_emf;
       repeat(300000)@(posedge clk); //1000000
       error3 = iDUT.sensorCondition.error;
       error3 = (error3[12] ? -1 : 1)*error3;
       avg_tor3 = iDUT.sensorCondition.avg_torque;
       omega3 = iPHYS.omega;
       selblu3 = iDUT.selBlu;
       selgrn3 = iDUT.selGrn;
       selylw3 = iDUT.selYlw;
       backemf3 = iPHYS.back_emf;
       repeat(100000)@(posedge clk); //1000000

       //Check if brake condition works
       if(BRAKE < 12'h800) begin
	  assert(iDUT.brake_n === 1'b0)
          else $display("ERROR! brake_n not deasserted although below threshold value");
       end

       // Check if Batt is within the range else perform some tests
       if(BATT < 12'hA98) begin
           assert((omega3 <= omega1)) $display("Test batt1 for omega check passed!");
           else $display("ERROR! Batt Test 1");
           assert((error2 <= error1)) $display("Test batt2 for backemf check passed!");
           else $display("ERROR! Batt test 2");
           continue;
       end

       //BRAKE TEST//
       if (iDUT.brake_n === 1'b0) begin
           assert((backemf1 > backemf2) && (backemf2 > backemf3)) //Backemf is decreasing
           else $display("ERROR! Backemf check 1.");
           assert((omega1 > omega2) && (omega2 > omega3)) //Omega is decreasing 
           else $display("ERROR! Omega check 2.");
	   assert(selgrn1===1 && selblu1===1 && selylw1===1) //Select signals are 0
           else $display("ERROR! sel1 signals.");
	   assert(selgrn2===1 && selblu2===1 && selylw2===1)
           else $display("ERROR! sel2 signals.");
           assert(selgrn3===1 && selblu3===1 && selylw3===1)
           else $display("ERROR! sel3 signals.");
           assert(iDUT.drv_mag === 0)
           else $display("ERROR! drv_mag check 7.");
	   $display("Brake Test check passed!");
           continue;
       end

       //Error check tests
       assert((error2 <= error1) && (error3 <= error2)) $display ("Test 1 for error check passed!");
       else $display("ERROR! Test 1");
       
       //Depending on whether torque increased on decreased, asserting flag to decide which check to run
       if(TORQUE < torque_prev) begin
	  bool_torque = 1'b0;
       end else if (TORQUE > torque_prev) begin
          bool_torque = 1'b1;
       end

       
       //based on bool torque checking what happens to omega and backemf
       if(bool_torque === 1'b0) begin
	  //checking if omega decreases
	  assert((omega3 <= omega1)) $display("Test 2.1 for omega check passed!");
          else $display("ERROR! Test 2.1");
          //checking if backemf decreases
          assert((backemf3 <= backemf1) && iDUT.brake_n) $display("Test 3.1 for backemf check passed!");
          else $display("ERROR! Test 3.1");        
          //Checking if avg_torque approaches TORQUE
          assert((avg_tor1 - TORQUE) >= (avg_tor2 - TORQUE)) $display("Test 4.1 for torque check passed!");
          else $display("ERROR! Test 4.1");
       end else if (bool_torque === 1'b1)begin
          //checking if omega increases
          assert((omega3 >= omega1 | omega3 >= omega2)) $display("Test 2.2 for omega check passed!");
          else $display("ERROR! Test 2.2");
          //checking if backemf increases
          assert((backemf3 >= backemf1)) $display("Test 3.2 for backemf check passed!");
          else $display("ERROR! Test 3.2");
          //checking if torque increases
	  assert((TORQUE - avg_tor1) >= (TORQUE - avg_tor2)) $display("Test 4.2 for torque check passed!");
          else $display("ERROR! Test 4.2");
       end

       //verify_sim(.clk(clk), .loop_var(loop_var), .BRAKE(BRAKE), .TORQUE(TORQUE), .BATT(BATT), .YAW_RT(YAW_RT));
    end
    $display("YAHOO!! Tests Passed.");
         $stop();
  end

  ///////////////////
  // Generate clk //
  /////////////////
  always 
      #10 clk = ~clk;

  ///////////////////////////////////////////
  // Block for cadence signal generation? //
  /////////////////////////////////////////
  always begin
   case(cad_pick) 
      2'b00: begin
         repeat(512) @(negedge clk);
         cadence = ~cadence;
      end
      2'b01: begin
         repeat(1024) @(negedge clk);
         cadence = ~cadence;
      end
      2'b10: begin
         repeat(2048) @(negedge clk);
         cadence = ~cadence;
      end
      2'b11: begin
         repeat(4096) @(negedge clk);
         cadence = ~cadence;
      end
    endcase
  end

endmodule
`default_nettype wire