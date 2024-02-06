// CSE140L 
// test bench for lab 5
module lab5_tb();

logic clk    = 0,                // clock source -- drives DUT input of same name
	  init   = 0;	             // init -- start the DUT -- drives DUT input
wire  done;		    	         // done -- DUT is done

logic      p8[15], p4[15], p2[15], p1[15], p0[15];   // Hamming block parity bits

logic[11:1] d2_in[15];           // use to generate data
logic[15:0] d2_good[15];         // d2_in w/ parity
logic[ 3:0] flip[15];            // position of corruption bit
logic[ 5:0] flip2[15];           // position of potential second corruption bit
logic[15:0] d2_bad[15], 
            d2_bad1[15];         // possibly corrupt messages w/ parity


logic[15:0] original_msg[15],
            recovered_msg[15];
int         score; 

/* your device goes here
 explicitly list ports if your names differ from test bench's = my starter top_level.sv
*/
top_level DUT(.*);

initial begin
  for(int i=0; i<15; i++) begin
// generate random 11-bit messages 
	d2_in[i] = '1;//$random;          // to change "random" sequence, try >>, e.g. $random>>2;
// Hamming 11:15 parity bits	
    p8[i] = ^d2_in[i][11:5];
    p4[i] = (^d2_in[i][11:8])^(^d2_in[i][4:2]); 
    p2[i] = d2_in[i][11]^d2_in[i][10]^d2_in[i][7]^d2_in[i][6]^d2_in[i][4]^d2_in[i][3]^d2_in[i][1];
    p1[i] = d2_in[i][11]^d2_in[i][ 9]^d2_in[i][7]^d2_in[i][5]^d2_in[i][4]^d2_in[i][2]^d2_in[i][1];
// global parity
    p0[i] = ^d2_in[i]^p8[i]^p4[i]^p2[i]^p1[i];
    
// Encode without error
	d2_good[i] = {d2_in[i][11:5],p8[i],d2_in[i][4:2],p4[i],d2_in[i][1],p2[i],p1[i],p0[i]};
	 
// Flip one bit
    flip[i] = i;//$random;
    d2_bad1[i] = d2_good[i] ^ (1'b1<<flip[i]);
// possibly flip second bit
	flip2[i] = $random;
	d2_bad[i] = d2_bad1[i] ^ (1'b1<<flip2[i]);
/* Note: if flip2[i] = flip[i], the bit flip errors cancel each other out (no error)
   else if flip2[i]<16, we have two errors -- can detect, cannot correct
   else (if flip2[i]>15), we have only one error, since flip2 is out of range -- expect to correct it 
*/    
// copy 15 encodings into mem[64:93] 
    $display("good = %b case %d flip   %b",d2_good[i],i,flip[i]);
    $display("bad  = %b                %b",d2_bad[i],flip2[i]);
    $display();
    DUT.dm1.core[65+2*i] = {d2_bad[i][15:8]};
    DUT.dm1.core[64+2*i] = {d2_bad[i][ 7:0]};
  end
  
  #10ns init   = 'b1;	// start DUT
  #10ns init   = 'b0;
  
  wait(done);			// wait for DUT to finish
  
  $display();
  $display("start lab5");
  $display();
  
  for(int i=0; i<15; i++) begin
	original_msg[i]  = {5'b0,d2_in[i]};                                 // leading 00 = 0 errors
    if(flip2[i][5:4]) original_msg[i] = {5'b01000,d2_in[i]};            // leading 01 = 1 error
	recovered_msg[i] = {DUT.dm1.core[95+2*i], DUT.dm1.core[94+2*i]};
    $display("flip  =   %b",flip[i]);
    $display("flip2 = %b",flip2[i]);
    $display("%b  Original Message", original_msg[i]);
    $display("%b  Message w/ parity", d2_good[i]);
    $display("%b  Corrupted Message", d2_bad[i]);
    $display("%b  Recovered Message", recovered_msg[i]);

    if((flip2[i][5:4]==0) && (flip2[i][3:0]!=flip[i])) begin             
      original_msg[i] = {5'b10000,d2_in[i]};                            // leading 10 = 2 errors 
	  $display("double error injected here");
	  if((DUT.dm1.core[95+2*i][7]==1'b0) || (DUT.dm1.core[95+2*i][7]===1'bx))
	    $display("missed the double error");
	  else
	    score++;
	end
	else if(original_msg[i] == recovered_msg[i]) begin
	  $display("we have a match");
      score++;
	end
	else begin 
      if(original_msg[i][10:0] != recovered_msg[i][10:0])
	    $display("Messages don't match!");
      case({original_msg[i][15:14],recovered_msg[i][15:14]})
        4'b01_00: $display("single error, not flagged");
        4'b01_10: $display("single error flagged as two");
        4'b00_01: $display("no error, but flaged as one");
        4'b00_10: $display("no error, but flagged as two");
        4'b10_00: $display("2 errors, none flagged");
        4'b10_01: $display("2 errors, flagged as one");
      endcase
    end
    $display(); 
	#10ns;
  end
  $display("score = %d/15",score);
  $stop;
end

always begin
  #5ns clk = 1;            // tic
  #5ns clk = 0;			   // toc
end										

endmodule
										   