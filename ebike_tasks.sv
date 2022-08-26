package ebike_tasks;

task automatic initialize(ref clk, RST_n, cadence,
			  ref [1:0] cad_pick, ref [9:0] loop_var);
   begin 
    clk = 0;
    loop_var = 10'b0;
    RST_n = 0;
    cad_pick = 2'b00;
    cadence = 0;
    @ (posedge clk);
    repeat (2) @(negedge clk);
    @(negedge clk) RST_n = 1'b1;
   end
endtask


task automatic verify_sim(ref clk, ref[9:0] loop_var, ref [11:0] BRAKE, TORQUE, BATT, ref [15:0] YAW_RT);
   begin
     $display("Starting sim %d: Brake: %x Torque: %x Batt: %x Incline: %x", loop_var, BRAKE, TORQUE, BATT, YAW_RT);
     //$display(ebike.sensorCondition.error);
     repeat(1000000)@(posedge clk);
     $display("Done with sim %d", loop_var);
   end
endtask

endpackage