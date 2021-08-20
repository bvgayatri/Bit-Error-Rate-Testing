# Bit-Error-Rate-Testing
BER testing project using verilog. It is used to measure the quality of a communication system. 
Description : 

module #1-->PRBS+Noise generataor
It generates PRBS signal of required length(out of given 4 sequencelengths:7,15,20,23 )
Then it generates a periodic noise bit that is added to the PRBS signal(Noise bit periodicity is also given by user: i.e 0 noise or 1 in 100,1000,10000 bits)
This PRBS added with noise is the output of first module.

module #2--> BER Tester module
The input t this module is the PRBS+Noise signal from previous module.
It initially takes the inputs scans it for a certain period and determines the length of the PRBS signal.
Then a signal of same length is locally generated.
It is synced with the incoming signal after which the module starts comparing the signal bit by bit with the locally generated signal.
The bit error rate is incremented with occurance of each bit difference.

(Burst errors due to noise, interference etc is also taken into consideration but not completely implemented.
if more than 4 continuos bit errors occure, then the burst error detection is activated and measured for a certain time. if the PRBS in the observation time is proper and within limit then the error count during this period is also aded into the BER count and the calculation continues.

In case the bit errors during observation time are greater than a threshold value, the coaprision is stopped and the module starts from beginning again i.e newly identify the sequence length,sync and compare)

