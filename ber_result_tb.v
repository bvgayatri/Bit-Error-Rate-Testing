`timescale 1ns / 1ps
module ber_result_tb;
reg clock;                 

reg reset;//prbsgen
reg [1:0]select_gen;//prbs_gen
reg [1:0]noise_gen; //prbs_gen            
reg prbs_in;

wire ledzero; 
wire lederror;             
wire led7;              
wire led15;                
wire led20;                
wire led23;                
wire prbs_out;//prbs_gen
wire [9:0]teb_out;
wire [31:0]ttb_out; 
//instantiate uut     
 ber_prbsnoise uut1(
   .clock(clock),
   .reset(reset),
   .select_gen(select_gen), 
   .noise_gen(noise_gen),  
   .prbs_out(prbs_out)
   );
   
ber_result uut2(               
  .clock(clock),                  
 
  .prbs_in(prbs_in),              
  .teb_out(teb_out), 
  .ledzero(ledzero),               
  .lederror(lederror),              
  .led7(led7),                  
  .led15(led15),                 
  .led20(led20),                 
  .led23(led23),                 
  //.ledstop(ledstop), 
  .ttb_out(ttb_out)     
  );   
  
initial 
 begin                             
   // Initialize Inputs                     
   clock = 0;                               
   reset = 0;                               
   select_gen = 2'b00;//generation control     
    noise_gen=2'b01;                                        
                                      
   #3 reset=1;                              
   #21 reset=0;
   
   
      
   
                             
 end  
  always@(posedge clock)
    begin
    #5
     prbs_in=prbs_out;
    end                                     
initial 
 forever 
  begin                 
     #3 clock=~clock;                       
  end                                                                           
endmodule
