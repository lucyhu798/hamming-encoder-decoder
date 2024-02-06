// shell for Lab 4 CSE140L
// this will be top level of your DUT
// W is data path width (8 bits)
// byte count = number of "words" (bytes) in reg_file
//   or data_memory
module top_level #(parameter W=8,
                   byte_count = 256)(
  input        clk, 
               init,	           // req. from test bench
  output logic done);	           // ack. to test bench

// memory interface = 
//   write_en, raddr, waddr, data_in, data_out: 
  logic write_en;                  // store enable for dat_mem

// address pointers for reg_file/data_mem
  logic[$clog2(byte_count)-1:0] raddr, waddr;

// data path connections into/out of reg file/data mem
  logic[W-1:0] data_in;
  wire [W-1:0] data_out; 

  logic       p0, p8, p4, p2, p1;   // Generated
  logic		  s0, s8, s4, s2, s1; 	// Received
  
/* instantiate data memory (reg file)
   Here we can override the two parameters, if we 
     so desire (leaving them as defaults here) */
  dat_mem #(.W(W),.byte_count(byte_count)) 
    dm1(.*);		               // reg_file or data memory

/* ********** insert your code here
   read from data mem, manipulate bits, write
   result back into data_mem  ************
*/
// program counter: bits[6:3] count passes through for loop/subroutine
// bits[2:0] count clock cycles within subroutine (I use 5 out of 8 possible, pad w/ 3 no ops)
  logic[ 6:0] count;
  logic[ 8:0] parity;
  logic[15:0] temp, temp1, temp2, tempData;
  logic[10:0] regen;
  logic[3:0] xorVal;
  logic       temp1_enh, temp1_enl, temp2_en;

  assign parity[8] = ^temp1[10:4];
//...

  always @(posedge clk)
    if(init) begin
      count <= 0;
      temp1 <= 'b0;
      temp2 <= 'b0;
    end
    else begin

      count                     <= count + 1;
      if(temp1_enh) temp1[15:8] <= data_out;
      if(temp1_enl) temp1[7:0] <= data_out;
      if(temp2_en) begin
			temp2		  <= temp;
			//$display("P value is : %b, s value is: %b", {p8,p4,p2,p1,p0}, {s8,s4,s2,s1,s0});
			//$display("our xor value is : %b",xorVal);
			//$display("our Regen value is : %b",regen);
		end
    end  

  always_comb begin
   s0 = temp1[0];
	s1 = temp1[1];
	s2 = temp1[2];
	s4 = temp1[4];
	s8 = temp1[8];
	
	regen = {temp1[15:9],temp1[7:5],temp1[3]};
	
	p8 = ^regen[10:4];                        // reduction parity (xor)
	p4 = (^regen[10:7])^(^regen[3:1]); 
	p2 = regen[10]^regen[ 9]^regen[6]^regen[5]^regen[3]^regen[2]^regen[0];
	p1 = regen[10]^regen[ 8]^regen[6]^regen[4]^regen[3]^regen[1]^regen[0];
	p0 = ^regen ^s8^s4^s2^s1;  // overall parity (0th bit)
	
	

	temp = {1'b1, 15'b0}; //2 errors 
	xorVal = {s8,s4,s2,s1}^{p8,p4,p2,p1};
	tempData = temp1;
	
	if ({s8,s4,s2,s1} == {p8,p4,p2,p1}) begin
		if ( s0 == p0) begin
			temp = {5'b00000,regen};			// no error
		end else begin
			temp = {5'b01000,regen};				// 1 error
		end
	end else begin
		if ( s0 != p0) begin
			if ( xorVal == 1 || xorVal == 2|| xorVal == 4|| xorVal == 8) begin
				temp = {5'b01000,regen};			//bad parity bit
			end else begin
				tempData[xorVal] = !temp1[xorVal]; //bad data bit
				temp = {5'b01000,tempData[15:9],tempData[7:5],tempData[3]};			
			end
		end
	end
	
	
// defaults  
    temp1_enl        = 'b0;
    temp1_enh        = 'b0;
    temp2_en         = 'b0;
    raddr            = 'b0;
    waddr            = 'b0;
    write_en         = 'b0;
    data_in          = temp2[7:0];   
    case(count[2:0])
      1: begin                  // step 1: load from data_mem into lower byte of temp1
           raddr     = 64+2*count[6:3];
           temp1_enl = 'b1;
         end  
      2: begin                  // step 2: load from data_mem into upper byte of temp1
           raddr      = 65+2*count[6:3];
           temp1_enh = 'b1;
         end
      3: temp2_en    = 'b1;     // step 3: copy from temp1 and parity bits into temp2
      4: begin                  // step 4: store from one bytte of temp2 into data_mem 
           write_en = 'b1;
           waddr    = 94+2*count[6:3];
           data_in  = temp2[7:0];
         end
      5: begin
           write_en = 'b1;      // step 5: store from other byte of temp2 into data_mem
           waddr    = 95+2*count[6:3];
           data_in  = temp2[15:8];
         end
    endcase
  end
  // automatically stop at count 127; 120 might be even better (why?)
  assign done = &count;
  
endmodule
