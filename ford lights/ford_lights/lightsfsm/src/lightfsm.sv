module lightfsm(input  logic clk,
                input  logic reset,
                input  logic left, right,
                output logic la, lb, lc, ra, rb, rc);	 
 
  // put your logic here	
  // next-state wires
  logic ns0, ns1, ns2, ns3;	 
  // state wires
  logic s0, s1, s2, s3;
  //logic functions outputs
  logic n_s3s2, n_s1s0;
  logic n_s0, n_s1, n_s2, n_s3;	
  // is idle
  logic not_is_idle, is_idle;
  // l r
  logic r_idle, l_idle;
  
  
  // flop copied from previous assignment (not that it's difficult to make one)
  flopr state_1(clk, reset, ns0, s0); 
  flopr state_2(clk, reset, ns1, s1);
  flopr state_3(clk, reset, ns2, s2);
  flopr state_4(clk, reset, ns3, s3);	
  // always_comb   
  
  not(n_s0, s0);
  not(n_s1, s1);
  not(n_s2, s2);
  not(n_s3, s3);
  
  
  and(is_idle, n_s0, n_s1, n_s2, n_s3);
  and(r_idle, is_idle, right);
  and(l_idle, is_idle, left);
  
  
  and(n_s3s2, n_s3, s2);  // left bit
  and(n_s1s0, n_s1, s0);  // right bit
  
  // needed for correct display
  
  
  // next-state
  or(ns0, r_idle, n_s1s0);
  buf(ns1, s0);
  or(ns2, l_idle, n_s3s2);	
  buf(ns3, s2);
  
  // outputs
  or(ra, s1, s0);	
  buf(rb, s1);
  and(rc, s1, n_s0);
  
  or(la, s3, s2);	 
  buf(lb, s3);
  and(lc, s3, n_s2);
            
  
endmodule

module testbench(); 
  logic        clk, reset;
  logic        left, right, la, lb, lc, ra, rb, rc;
  logic [5:0]  expected;
  logic [6:0]  hash;
  logic [31:0] vectornum, errors;
  logic [7:0]  testvectors[10000:0];

  // instantiate device under test 
  lightfsm dut(clk, reset, left, right, la, lb, lc, ra, rb, rc); 

  // generate clock 
  always 
    begin
      clk=1; #5; clk=0; #5; 
    end 

  // at start of test, load vectors and pulse reset
  initial 
    begin
      $readmemb("lightfsm.tv", testvectors); 
      vectornum = 0; errors = 0; hash = 0; reset = 1; #22; reset = 0; 
    end 

  // apply test vectors on rising edge of clk 
  always @(posedge clk) 
    begin
      #1; {left, right, expected} = testvectors[vectornum]; 
    end 

  // check results on falling edge of clk 
  always @(negedge clk) 
    if (~reset) begin    // skip during reset
      if ({la, lb, lc, ra, rb, rc} !== expected) begin // check result 
        $display("Error: inputs = %b", {left, right});
        $display(" outputs = %b %b %b %b %b %b (%b expected)", 
		la, lb, lc, ra, rb, rc, expected); 		
		$display("Mem: %h %h %h %h", dut.s0, dut.s1, dut.s2, dut.s3);
        errors = errors + 1; 
      end
      vectornum = vectornum + 1;
      hash = hash ^ {la, lb, lc, ra, rb, rc};
      hash = {hash[5:0], hash[6] ^ hash[5]};
      if (testvectors[vectornum] === 8'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors); 
        $display("Hash: %h", hash);
        $stop; 
      end 
    end 
endmodule 
 
