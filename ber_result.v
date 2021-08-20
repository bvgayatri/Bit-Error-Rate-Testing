//error while implmentation: bursterror_counter has multiple drivers 
//measures totalised and exponential errors

//teb=total error bits ttb=total tested bits
/*Description
1.prbs seq(with or without noise) is generated in another fpga block
2. the output of that block is fed as input to the present block
3.in seq detection-when bursterrorflag is 1 continuos matches are only
  and if threshold is reached seq is assigned. while assigning seq bursterrorflag is made 0 to
  stop the seq detection(it will be 1 again if burst errors occur)
4.after seq is detected by counting continuos matches, the seq in shiftreg_seqdetect is
parallelly loaded inti shiftreg_local
5.feedback is calculated in shiftreg local and prbs_local output is generated
6.the o/p of prbs_local and prbs_seqdetect are compared(based on the seq) and respective 
error is incremented and assigned to the error counter
---this is the general case
if any burst of error occurs then the burst error detection detects it as follows
1.counting of mismatches is done for continuos 4 errors
2.if more than 4 continuos errors occur then,the old seq is stored in register old_seq
 .reference counter(counts 50 clocks ) & bursterrorbits_buf(counts discountinuities also) start.
3.after 50 clk cycles if bursterror counter>25 then bursterror_flag set to 1(seq detect satrts)
4.save the new seq as new_seq.
5.if new_seq=old_seq then add the bursterrorbits_buf value to totalerror_counter
6.if not equal,set totalerrorcounter =0,bursterrorbits_buf=0;
flag is set to 0 automatically  once seq is detected(in the seq detect block)*/
`timescale 1ns / 1ps

module ber_result(
   input clock,
   input reset,
   input prbs_in,
   input mode_select,//0 for totalised, 1 for exponential
   output ledzero,  
   output lederror, 
   output led7,     
   output led15,    
   output led20,    
   output led23, 
   
   output [9:0]teb_out,
   output [31:0]ttb_out    
   );

//variable declaration

//----------------sequence detection variables------------ 
reg [22:0]shiftreg_seqdetect;                                                                   
wire [3:0]feedback_seqdetect;/*4 feedbacks tested parallely
(0=7bit,1=15bit,2=20bit,3=23bit)*/ 

reg prbs_seqdetect;      //o/p from seqdetect lfsr (to be compared to ber lfsr)                                                                                                                               
wire match7;//feedbacks are ||ly xored with prbs_gen 
wire match15;  //and generate 4 matches                                                                                                  
wire match20;                                                                                
wire match23;                                                                                
                                                                                              
reg [4:0]counter7=0;  //counter7,15,20,23 count the no. of                                                                           
//continuos matches from match7,15.. and used to select seq 
reg [4:0]counter15=0;                                                                            
reg [4:0]counter20=0;                                                                           
reg [4:0]counter23=0;                                                                                                                                                                                                                                                 
reg [3:0]match=0;                                                                                
reg [1:0]seqbuffer; 
                                                                           
reg bursterror_flag=1;
//if bursterror occurs- flag=1;else 0
// if burst error-detect seq, else lock the seq                                                                                              
 //o/p indicators                                                                                        
 reg led0_buf=0,lederror_buf=0,led7_buf=0;
 reg led15_buf=0,led20_buf=0,led23_buf=0;                                                         
//-------------local seq generator---------
reg [22:0]shiftreg_local=0;//local shiftreg to generate pn sequence
reg feedback_local;  //feedback of ber lfsr                                                                                                                         

reg prbs_local; //single o/p from muxing prbs_local lines
// and selecting through seq buffer 
 
//-------------error count---------------
reg mismatch7=0;// counts errors in selected seq
reg mismatch15=0; //i.e compares prbs_local and prbs_seqdetect                                      
reg mismatch20=0;                                       
reg mismatch23=0;                                       
integer errorcounter7=0;                                            
integer errorcounter15=0;                                           
integer errorcounter20=0;                                           
integer errorcounter23=0; 

integer errorcounter_total;  

//--------------total bits count   
integer ttb_out_buffer;  
integer ttb_totalised_buffer=0;                                   
//--------------burst error detection-------
//if 4 continuos mismatches occur then test for burst errors is done  
reg [5:0]burst_clkcounter=0; //ref counter counts the clock 50 times
reg [5:0]bursterror_counter=0;
reg [5:0]bursterrorbits_buf=0;
reg [1:0]old_seq;
reg [1:0]new_seq;
reg ttb_exp_buffer=3;
reg [10:0]bursterror_out_buf=0;
reg [31:0]burst_clkcounter_final=0;
reg lock_sequence=1;
//program logic


//----------------seq detection block----------------

always@(posedge clock)                                       
  begin                                                      
                                                             
    shiftreg_seqdetect={shiftreg_seqdetect[21:0],prbs_in};            
 end                                                         
   //assign feedbacks parallely                              
assign feedback_seqdetect[0]=shiftreg_seqdetect[6]^shiftreg_seqdetect[5];   
assign feedback_seqdetect[1]=shiftreg_seqdetect[14]^shiftreg_seqdetect[13]; 
assign feedback_seqdetect[2]=shiftreg_seqdetect[19]^shiftreg_seqdetect[16]; 
assign feedback_seqdetect[3]=shiftreg_seqdetect[22]^shiftreg_seqdetect[17]; 
//compare prbsnoise and feedback
assign match7 =prbs_in^feedback_seqdetect[0]; 
assign match15=prbs_in^feedback_seqdetect[1];
assign match20=prbs_in^feedback_seqdetect[2];
assign match23=prbs_in^feedback_seqdetect[3];

//seq detect based on match value
 
always@(posedge clock)
/* if((seqbuffer!=2'b00|seqbuffer!=2'b01|seqbuffer!=2'b10|
seqbuffer!=2'b11)& (bursterror_flag==1'b1)
 */
if(bursterror_flag==1'b1)  
   begin
    if(match7==0)
      counter7=counter7+1;
    else
     begin
      if(match7!=0)                                         
      counter7=0; 
     end
        
    if(match15==0)           
      counter15=counter15+1;   
    else
    begin
     if(match15!=0)                     
      counter15=0;
    end
    if(match20==0)            
     counter20=counter20+1;    
    else
    begin
     if(match20!=0)                    
      counter20=0;         
   end  
    if(match23==0)          
     counter23=counter23+1;  
    else 
    begin
      if(match23!=0)                   
     counter23=0;
    end  
   //set the respective bit in match if the counter reaches threshold value
  if(counter7==5'd12)//not 7 because initially
  // seq matches with 11 bits & indicates wrong seq
   match[0]=1'b1;
  else
   match[0]=1'b0;
  if(counter15==5'd15)
   match[1]=1'b1;
  else          
   match[1]=1'b0;
  if(counter20==5'd20)
   match[2]=1'b1;
  else          
   match[2]=1'b0;
  if(counter23==5'd23)
   match[3]=1'b1;
  else          
   match[3]=1'b0;
end  

always@* 
 begin
//based on match value(of selected seq) on the respective led
 case(match)
   4'b0000:begin              
            led0_buf=1;             
                   
            //lederror_buf=0;           
           end                
   4'b0001: begin
            led7_buf=1; 
            led15_buf=0;
            led20_buf=0;
            led23_buf=0;                          
            lederror_buf=0;             
            led0_buf=0;             
              
            seqbuffer=2'b00;
            bursterror_flag=1'b0;  
            end               
   4'b0010:begin
            led7_buf=0; 
            led15_buf=1;
            led20_buf=0;
            led23_buf=0;     
            lederror_buf=0;            
            led0_buf=0;           
            seqbuffer=2'b01;
            bursterror_flag=1'b0; 
            end               
   4'b0100:begin 
           led7_buf=0; 
           led15_buf=0;
           led20_buf=1;             
           led23_buf=0;
           lederror_buf=0;              
           led0_buf=0;              
           seqbuffer=2'b10;
           bursterror_flag=1'b0;   
           end                
   4'b1000: begin      
            led7_buf=0;
            led15_buf=0;
            led20_buf=0;       
            led23_buf=1;            
            lederror_buf=0;             
            led0_buf=0;             
            seqbuffer=2'b11;
            bursterror_flag=1'b0;  
            end               
    
    default: lederror_buf=1; 
endcase 
new_seq=seqbuffer;
end 
//assigning led value to outputs
assign ledzero=led0_buf;
assign lederror=lederror_buf;
assign led7=led7_buf;
assign led15=led15_buf;
assign led20=led20_buf;
assign led23=led23_buf;  


//-------------local seq generation 

   always@(posedge clock)//if seq is detected-then(load if shftreg is 0 ,otherwise shift)
if(seqbuffer==2'b00 |seqbuffer==2'b01 |seqbuffer==2'b10 |seqbuffer==2'b11 ) 
 if(shiftreg_local==23'b0)
   begin     
    shiftreg_local={shiftreg_seqdetect[22:0]};
   end   
  else      
     begin
      shiftreg_local={shiftreg_local[21:0],feedback_local};
      //assign o/p for prbs_local
  end   
  
always@*
  case(seqbuffer)
    2'b00:begin                                              
           prbs_seqdetect=shiftreg_seqdetect[6];                       
           prbs_local=shiftreg_local[6];                               
           feedback_local=shiftreg_local[6]^shiftreg_local[5];     
          end                                                
    2'b01:begin                                              
           prbs_seqdetect=shiftreg_seqdetect[14];                      
           prbs_local=shiftreg_local[14];                              
           feedback_local=shiftreg_local[14]^shiftreg_local[13];   
          end                                                
    2'b10:begin                                              
            prbs_seqdetect=shiftreg_seqdetect[19];                     
            prbs_local=shiftreg_local[19];                            
            feedback_local=shiftreg_local[19]^shiftreg_local[16];  
          end                                                
    2'b11:begin                                               
             prbs_seqdetect=shiftreg_seqdetect[22];                    
             prbs_local=shiftreg_local[22];                            
             feedback_local=shiftreg_local[22]^shiftreg_local[17]; 
          end                                                
  
  endcase
  //-------------bit error count---------------   
  //error count
  always@(posedge clock)
  if(bursterror_flag==1'b0)
   begin
     case(seqbuffer)
      2'b00:begin
             if(prbs_local^prbs_seqdetect==1'b1)
               errorcounter7=errorcounter7+1;
            end 
      2'b01:begin                                   
             if(prbs_local^prbs_seqdetect==1'b1)                        
               errorcounter15=errorcounter15+1;      
           end                                      
      2'b10:begin                                
              if(prbs_local^prbs_seqdetect==1'b1)                               
                errorcounter20=errorcounter20+1;
              end                                    
      2'b11:begin                               
              if(prbs_local^prbs_seqdetect==1'b1)                        
                errorcounter23=errorcounter23+1;     
            end 
     endcase                                   
  end           
 always@*
  case(seqbuffer)
   2'b00:errorcounter_total=errorcounter7;
   2'b01:errorcounter_total=errorcounter15;
   2'b10:errorcounter_total=errorcounter20;
   2'b11:errorcounter_total=errorcounter23;
  endcase 
  //total bit count
  always@(posedge clock)
   
     if(ttb_totalised_buffer==32'hffffffff)//integer limit reached
       ttb_totalised_buffer=1'b0;
     else 
       ttb_totalised_buffer=ttb_totalised_buffer+1; 
       
                

 //-----------burst error detection---------
  /*   always@(posedge clock)//checks for 4 continuos errors and
      begin
      if((burst_clkcounter>=6'd50)|(bursterror_counter<6'd4)|(old_seq!=new_seq))
        burst_clkcounter=0;
         
       if(burst_clkcounter<6'd49)
          burst_clkcounter=burst_clkcounter+1;
         
       if((prbs_local^prbs_seqdetect!=1'b1)&(bursterror_counter<6'd4))//if mismatch
        bursterror_counter=0; 
       else if(prbs_local^prbs_seqdetect==1'b1)
        bursterror_counter= bursterror_counter+1;
      end 
      
 always@* //if 4 consecutive mismatches then continues else makes it 
 begin
   if(bursterror_counter>=6'd4)
    lock_sequence=1'b1;
 end 
 always@*
  begin  
    if(lock_sequence==1'b1)
    begin
      old_seq=seqbuffer;
      bursterror_flag=1'b1;//to start seq detection 
      if((bursterror_counter>=6'd25)&(burst_clkcounter==6'd48))
        begin
           if(old_seq==new_seq)
            begin
             bursterrorbits_buf=bursterror_counter;
             burst_clkcounter_final=burst_clkcounter;
            
            end
           else
             begin
              bursterrorbits_buf=0;
              errorcounter_total=0;
              bursterror_counter=0;
              burst_clkcounter_final=0;
             end
       end     
    end 
  end */
assign ttb_out=ttb_totalised_buffer+burst_clkcounter_final;     
assign teb_out=errorcounter_total+ bursterrorbits_buf;                                                                                                
endmodule


