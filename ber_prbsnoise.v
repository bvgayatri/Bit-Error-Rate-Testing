//generates prbs sequence (with inputs-seq_select[3:0] and noise_gen[3:0])
//seq_select=7,15,20,23     noise_gen=0,100,1000,10000


/*Description
1.prbs is generated(noise is induced i.e bit is reversed once in every x(depends on 
noise_gen) bits
2.the prbs_out is given to output pin
`timescale 1ns / 1ps
*/
module ber_prbsnoise(
   input clock,
   input reset,
   input [1:0]select_gen,
   input [1:0]noise_gen,  
   output prbs_out    
   );
 
//variable declaration

//-------------- prbsnoise generaration variables
//for generation
reg [22:0]shiftreg;
reg feedback;
reg prbsbuffer;
//for error generation
integer noise_counter=0;
reg counteroverflow_gen;
reg [15:0]counterlimit;

//program logic
//---------------generation block--------------------
//prbs sequence generation

always@(posedge clock)//load or shift register (for generation
begin
 if(reset==1'b1)
  shiftreg=23'hffffff;
else
shiftreg={shiftreg[21:0],feedback};
end

always@*// calculate feedback based on the case selected
case(select_gen)
2'b00:feedback=shiftreg[6]^shiftreg[5];      
2'b01:feedback=shiftreg[14]^shiftreg[13];
2'b10:feedback=shiftreg[19]^shiftreg[16];
2'b11:feedback=shiftreg[22]^shiftreg[17];
default feedback=1'bx;
endcase

always@*//calculate output register based on sequence selected
case(select_gen)
 2'b00: prbsbuffer=shiftreg[6];
 2'b01: prbsbuffer=shiftreg[14];
 2'b10: prbsbuffer=shiftreg[19];
 2'b11: prbsbuffer=shiftreg[22];
default prbsbuffer=1'bx;
endcase

// noise or error insertion
always@*
 begin
  case (noise_gen)
   2'b00:counterlimit=1'b0;
   2'b01:counterlimit=16'd100;
   2'b10:counterlimit=16'd1000;
   2'b11:counterlimit=16'd10000;
   endcase
 end
always@(posedge clock)
//count upto a value&set counteroverflow if value reached
if(noise_gen==2'b00)
 counteroverflow_gen=1'b0;
else 
begin
  if(reset | counterlimit==noise_counter)
    begin
     noise_counter=0;
     counteroverflow_gen=1;
    end
  else
    begin
    noise_counter=noise_counter+1;
    counteroverflow_gen=0;  
    end
end 

//xor the noise(counteroverflow) and prbs output to induce 1 error in every x bits 
assign prbs_out=prbsbuffer^counteroverflow_gen;

endmodule
