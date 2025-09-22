// aludec.sv
// trao@g.hmc.edu 15 January 2020
// Updated for RISC-V Architecture

module aludecoder(input  logic [1:0] ALUOp,
                  input  logic [2:0] funct3,
                  input  logic op_5, funct7_5,
                  output logic [2:0] ALUControl);
              
    // For Lab 2, write a structural Verilog model 
    // use and, or, not
    // do not use assign statements, always blocks, or other behavioral Verilog
    // Example syntax to access bits to make ALUControl[0] = ~funct3[0]
    //  not g1(ALUControl[0], funct3[0]);
    // This is just an example; replace this with correct logic!			   
	logic aluop1_n;
	logic aluop0_n;
	logic partial_sum;
	logic beq_op;
	logic sub_op;
	logic slt_or_op;
	  
		
	not aluop_neg1(aluop1_n, ALUOp[1]);
	not aluop_neg0(aluop0_n, ALUOp[0]);
	
	logic funct3_n_2,  funct3_n_1,  funct3_n_0;
	not funct3_neg_2(funct3_n_2,funct3[2]);
	not funct3_neg_1(funct3_n_1,funct3[1]);
	not funct3_neg_0(funct3_n_0,funct3[0]);
	
	
	and ALUbit2(ALUControl[2], ALUOp[1], aluop0_n, funct3_n_2, funct3[1], funct3_n_0);
	and ALUbit1(ALUControl[1], ALUOp[1], aluop0_n, funct3[2], funct3[1]);
	and (beq_op, aluop1_n, ALUOp[0]);
	and part1(partial_sum, ALUOp[1], aluop0_n);
	and sub(sub_op,funct3_n_2,  funct3_n_1, funct3_n_2, partial_sum, op_5, funct7_5);
	and slt_or(slt_or_op, partial_sum, funct3[1], funct3_n_0);
	or ALUbit0(ALUControl[0], sub_op, slt_or_op, beq_op);

endmodule

module testbench #(parameter VECTORSIZE=10);
  logic                   clk;
  logic                   op_5, funct7_5;
  logic [1:0]             ALUOp;
  logic [2:0]             funct3;
  logic [2:0]             ALUControl, ALUControlExpected;
  logic [6:0]             hash;
  logic [31:0]            vectornum, errors;
  // 32-bit numbers used to keep track of how many test vectors have been
  logic [VECTORSIZE-1:0]  testvectors[1000:0];
  logic [VECTORSIZE-1:0]  DONE = 'bx;
  
  // instantiate device under test
  aludecoder dut(ALUOp, funct3, op_5, funct7_5, ALUControl);
  
  // generate clock
  always begin
   clk = 1; #5; clk = 0; #5; 
  end
  
  // at start of test, load vectors and pulse reset
  initial begin
    $readmemb("aludecoder.tv", testvectors); // Students may have to add a file path if ModelSim set up incorrectly
    vectornum = 0; errors = 0;
    hash = 0;
  end
    
  // apply test vectors on rising edge of clk
  always @(posedge clk) begin
    #1; {ALUOp, funct3, op_5, funct7_5, ALUControlExpected} = testvectors[vectornum];
  end
  
  // Check results on falling edge of clock.
  always @(negedge clk)begin
      if (ALUControl !== ALUControlExpected) begin // result is bad
      $display("Error: inputs=%b %b %b %b", ALUOp, funct3, op_5, funct7_5);
      $display(" outputs = %b (%b expected)", ALUControl, ALUControlExpected);
      errors = errors+1;
    end
    vectornum = vectornum + 1;
    hash = hash ^ {ALUControl};
    hash = {hash[5:0], hash[6] ^ hash[5]};
    if (testvectors[vectornum] === DONE) begin
      #2;
      $display("%d tests completed with %d errors", vectornum, errors);
      $display("Hash: %h", hash);
      $stop;
    end
  end
endmodule