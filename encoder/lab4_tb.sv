// CSE140L  Lab 4
// test bench
module lab4_tb();

logic clk    = 'b0,                 // clock source -- drives DUT input of same name
	  init   = 'b0;	                // init -- start the DUT -- drives DUT input
wire  done;		    	            // done -- DUT is has computed answer

logic[11:1] d1_in[15];           // original 11- bit messages, one-indexed
logic       p0, p8, p4, p2, p1;   // Hamming block parity bits
logic[15:0] d1_out[15];          // orig messages w/ parity inserted, zero-indexed

logic [15:0] expected_encoding,
             your_encoding;


// your device goes here
// explicitly list ports if your names differ from test bench's
top_level DUT(.*);

initial begin

  for(int i=0;i<15;i++)	begin
    d1_in[i] = $random;        // create 15 messages
	 
// copy 15 original messages into first 30 bytes of memory 
// rename "dm1" and/or "core" if you used different names for these
    DUT.dm1.core[2*i+1]  = {5'b0,d1_in[i][11:9]};
    DUT.dm1.core[2*i]    =       d1_in[i][ 8:1];
  end
  
  #10ns init   = 1'b1;          // start DUT
  #10ns init   = 1'b0;
  
  wait(done);                   // wait for DUT to finish
  
  $display("start lab4");
  $display();

// generate parity for each message; display result and that of DUT  
  for(int i=0;i<15;i++) begin
    p8 = ^d1_in[i][11:5];                        // reduction parity (xor)
    p4 = (^d1_in[i][11:8])^(^d1_in[i][4:2]); 
    p2 = d1_in[i][11]^d1_in[i][10]^d1_in[i][7]^d1_in[i][6]^d1_in[i][4]^d1_in[i][3]^d1_in[i][1];
    p1 = d1_in[i][11]^d1_in[i][ 9]^d1_in[i][7]^d1_in[i][5]^d1_in[i][4]^d1_in[i][2]^d1_in[i][1];
    p0 = ^d1_in[i]^p8^p4^p2^p1;  // overall parity (0th bit)
	 
// assemble output (data with parity embedded)
	expected_encoding = {d1_in[i][11:5],p8,d1_in[i][4:2],p4,d1_in[i][1],p2,p1,p0};
    your_encoding     = {DUT.dm1.core[31+2*i],DUT.dm1.core[30+2*i]};
	 
    $displayb ("%b  Message", d1_in[i]);
    $displayb ("%b  Expected Encoding", expected_encoding);
	$displayb ("%b  Your Encoding", your_encoding);

	assert (expected_encoding == your_encoding)
	  else $display("Encodings don't match!");

	$display(); 
	#10ns;
  end
  
  $stop;
end

always begin
  #5ns clk = 1;            // tic
  #5ns clk = 0;			   // toc
end										

endmodule
										   