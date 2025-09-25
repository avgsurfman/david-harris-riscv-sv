module priorityencoder(input  logic [7:1] a,
                       output logic [2:0] y);
              
    // For Lab 2, write a structural Verilog model 
    // use and, or, not
    // do not use assign statements, always blocks, or other behavioral Verilog
    
    logic a_7to4_neg_a3, a_7to4_neg_a2;
    logic a_7to5_neg;
    logic a_7to2_neg;

    logic a_7_n, a_6_n, a_5_n, a_4_n, a_3_n,  a_2_n,  a_1_n;
    not(a_7_n, a[7]);
    not(a_6_n, a[6]);
    not(a_5_n, a[5]);
    not(a_4_n, a[4]);
    not(a_3_n, a[3]);
    not(a_2_n, a[2]);

    or(y[2], a[7], a[6], a[5], a[4]);  
    and(a_7to4_neg_a3,a_7_n, a_6_n, a_5_n, a_4_n, a[3]);
    and(a_7to4_neg_a2,a_7_n, a_6_n, a_5_n, a_4_n, a[2]);
    or(y[1], a[7], a[6], a_7to4_neg_a3, a_7to4_neg_a2);

    and(a_7to5_neg, a_7_n, a_6_n, a[5]);
    and(a_7to2_neg, a_7_n, a_6_n, a_5_n, a_4_n, a_3_n, a_2_n, a[1]);
  
    or(y[0], a[7], a_7to5_neg, a_7to4_neg_a3, a_7to2_neg); 

endmodule

module testbench #(parameter VECTORSIZE=10);
  logic                   clk;
  logic [7:1]             a;
  logic [2:0]             y, yexpected;
  logic [6:0]             hash;
  logic [31:0]            vectornum, errors;
  // 32-bit numbers used to keep track of how many test vectors have been
  logic [VECTORSIZE-1:0]  testvectors[1000:0];
  logic [VECTORSIZE-1:0]  DONE = 'bx;
  
  // instantiate device under test
  priorityencoder dut(a, y);
  
  // generate clock
  always begin
   clk = 1; #5; clk = 0; #5; 
  end
  
  // at start of test, load vectors and pulse reset
  initial begin
    $readmemb("priorityencoder.tv", testvectors);
    vectornum = 0; errors = 0;
    hash = 0;
  end
    
  // apply test vectors on rising edge of clk
  always @(posedge clk) begin
    #1; {a, yexpected} = testvectors[vectornum];
  end
  
  // Check results on falling edge of clock.
  always @(negedge clk)begin
      if (y !== yexpected) begin // result is bad
      $display("Error: inputs=%b", a);
      $display(" outputs = %b (%b expected)", y, yexpected);
      errors = errors+1;
    end
    vectornum = vectornum + 1;
    hash = hash ^ y;
    hash = {hash[5:0], hash[6] ^ hash[5]};
    if (testvectors[vectornum] === DONE) begin
      #2;
      $display("%d tests completed with %d errors", vectornum, errors);
      $display("Hash: %h", hash);
      $stop;
    end
  end
endmodule

