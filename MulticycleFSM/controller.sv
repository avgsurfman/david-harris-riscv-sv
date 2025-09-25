//package multicycle_fsm;

// controller.sv
//
// This file is for HMC E85A Lab 5.
// Place controller.tv in same computer directory as this file to test your multicycle controller.
//
// Starter code last updated by Ben Bracker (bbracker@hmc.edu) 1/14/21
// - added opcodetype enum
// - updated testbench and hash generator to accomodate don't cares as expected outputs
// Solution code by Franciszek ("avgsurfman" "asicfl0w" "fmoszczuk") Moszczuk

typedef enum logic[6:0] {r_type_op=7'b0110011, i_type_alu_op=7'b0010011, lw_op=7'b0000011, sw_op=7'b0100011, beq_op=7'b1100011, jal_op=7'b1101111} opcodetype;

typedef enum logic[3:0] { 
    Fetch = 4'h0,
    Decode = 4'h1,
    MemAdr = 4'h2,
    MemRead = 4'h3,
    MemWB   = 4'h4,
    MemWriteS = 4'h5,
    ExecuteR = 4'h6,
    ALUWB = 4'h7,
    ExecuteI = 4'h8,
    JAL = 4'h9,
    Beq = 4'hA,
    Err = 4'hF
} statetype;

// localparam hack - slightly redundant but 
// captures the idea behind state 
// number/enconding/name separation
// provided new ALUOps are added
// Shouldn't affect synthesis that much...

/*localparam statetype Fetch =  S0;
localparam statetype Decode = S1;
// lb zone
localparam statetype MemAdr = S2;
localparam statetype MemRead = S3;
localparam statetype MemWB = S4;
// sw zone
localparam statetype MemWrite = S5;
// ALU Ops
localparam statetype ExecuteR = S6;
localparam statetype ALUWB = S7;
localparam statetype ExecuteI = S8;
// jal
localparam statetype JAL = S9;
// beq
localparam statetype Beq = S10;
// err
localparam statetype Err = S15;
*/


module controller(input  logic       clk,
                  input  logic       reset,  
                  input  opcodetype  op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  input  logic       Zero,
                  output logic [1:0] ImmSrc,
                  output logic [1:0] ALUSrcA, ALUSrcB,
                  output logic [1:0] ResultSrc, 
                  output logic       AdrSrc,
                  output logic [2:0] ALUControl,
                  output logic       IRWrite, PCWrite, 
                  output logic       RegWrite, MemWrite);


/// regs

statetype state, nextstate; 

always_ff @(posedge clk, posedge reset)
    if (reset) state <= Fetch;
    else state <= nextstate;

/// wires

logic [1:0] ALUOp;

logic PCUpdate, Branch, zero_branch;

//assign PCWrite = PCUpdate;
and(zero_branch, Branch, Zero);
or(PCWrite, PCUpdate, zero_branch);

always_comb begin
case(state)
    /// Entry
    Fetch: begin
    AdrSrc = 1'b0;
    IRWrite = 1'b1;
    ALUSrcA = 2'b00;
    ALUSrcB = 2'b10;
    ALUOp  = 2'b00;
    ResultSrc = 2'b10; 
    PCUpdate = 1'b1;
    RegWrite = 1'b0;
    MemWrite = 1'b0;
    Branch = 1'b0;
    
    nextstate = Decode;
    end
    
    /// Decode phase
    Decode: begin
    AdrSrc = 1'b0;
    IRWrite = 1'b0;     // changes
    ALUSrcA = 2'b01;
    ALUSrcB = 2'b01;
    ALUOp  = 2'b00;     // changes
    ResultSrc = 2'b00;  // changes
    PCUpdate = 1'b0;     // changes

    RegWrite = 1'b0;
    MemWrite = 1'b0;
    Branch = 1'b0;

    if ( op == lw_op || op == sw_op ) nextstate = MemAdr;
    if ( op == r_type_op) nextstate = ExecuteR;
    if ( op == i_type_alu_op) nextstate = ExecuteI;
    if ( op ==  jal_op) nextstate = JAL;
    if ( op ==  beq_op)  nextstate = Beq;
    end
     
    MemAdr: begin
    /// Changed signals first
    ALUSrcA = 2'b10; 
    ALUSrcB = 2'b01;
    ALUOp  = 2'b00;
    
    ResultSrc = 2'b00; 
    PCUpdate = 1'b0;  
    AdrSrc = 1'b0;
    IRWrite = 1'b0;
    RegWrite = 1'b0;
    MemWrite = 1'b0;
    Branch = 1'b0;

    if ( op == lw_op) nextstate = MemRead;
    else nextstate = MemWriteS;
    end

    MemRead: begin

    ResultSrc = 2'b00;
    AdrSrc = 1;

    IRWrite   = 1'b0;
    ALUSrcA   = 2'b00;
    ALUSrcB   = 2'b00;
    ALUOp    = 2'b00;
    ResultSrc = 2'b00; 
    PCUpdate   = 1'b0;
    RegWrite = 1'b0;
    MemWrite = 1'b0;
    Branch = 1'b0;

    nextstate = MemWB;
    end

    MemWB: begin
    
    ResultSrc = 2'b01;
    RegWrite = 1'b1;
    
    IRWrite   = 1'b0;
    ALUSrcA   = 2'b00;
    ALUSrcB   = 2'b00;
    ALUOp    = 2'b00;
    PCUpdate   = 1'b0;
    MemWrite = 1'b0;
    Branch = 1'b0;
    
    nextstate = Fetch;
    end


    MemWriteS: begin
    
    ResultSrc = 2'b00;
    MemWrite = 1'b1;
    AdrSrc = 1'b1;

    
    IRWrite = 1'b0;
    ALUSrcA = 2'b00;
    ALUSrcB = 2'b00;
    ALUOp  = 2'b00;
    ResultSrc = 2'b00; 
    PCUpdate = 1'b0;
    RegWrite = 1'b0;
    Branch = 1'b0;
    
  
    nextstate = Fetch;

    
    end
    /// DONE
    // End of Path
    
    //// ALU Ops
    ExecuteR: begin

    ALUSrcA = 2'b10;
    ALUSrcB = 2'b00;
    ALUOp = 2'b10;

    AdrSrc = 1'b0;
    IRWrite   = 1'b0;
    ResultSrc = 2'b00; 
    PCUpdate   = 1'b0;
    RegWrite = 1'b0;
    MemWrite = 1'b0;
    Branch = 1'b0;

    
    nextstate = ALUWB;
    end

    ALUWB: begin
    ResultSrc = 2'b00;
    RegWrite = 1'b1;

    ALUSrcA = 2'b00;
    ALUSrcB = 2'b00;
    ALUOp = 2'b00;
    AdrSrc = 1'b0;
    IRWrite   = 1'b0;
    PCUpdate   = 1'b0;
    MemWrite = 1'b0;
    Branch = 1'b0;

    nextstate = Fetch;
    end
       
    ExecuteI: begin
    ALUSrcA = 2'b10;
    ALUSrcB = 2'b01;
    ALUOp = 2'b10;

    AdrSrc = 1'b0;
    IRWrite   = 1'b0;
    ResultSrc = 2'b00; 
    PCUpdate   = 1'b0;
    RegWrite = 1'b0;
    MemWrite= 1'b0;
    Branch = 1'b0;

    nextstate = ALUWB;
    end
      
    JAL: begin
    ALUSrcA = 2'b01;
    ALUSrcB = 2'b10;
    ALUOp = 2'b00;
    ResultSrc = 2'b00;
    PCUpdate = 1'b1;

    AdrSrc = 1'b0;
    IRWrite   = 1'b0; 
    RegWrite = 1'b0;
    MemWrite = 1'b0;
    Branch = 1'b0;

    nextstate = ALUWB;
    end
        
    //// BEQ
    Beq: begin
    ALUSrcA = 2'b10;
    ALUSrcB = 2'b00;
    ALUOp = 2'b01;
    ResultSrc = 2'b00;
    Branch = 1'b1;

    
    IRWrite   = 1'b0;
    PCUpdate   = 1'b0;
    RegWrite = 1'b0;
    MemWrite = 1'b0;

    

    nextstate = Fetch;
    end

    default: nextstate = Err;

endcase 
end

//// 
//// ALUdecoder

aludecoder aludec(ALUOp,
                   funct3,
                   op[5],
                   funct7b5,
                   ALUControl);

InstrDecoder instrdec( op, ImmSrc);

endmodule

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

module InstrDecoder(input logic [6:0] op, 
                    output logic [1:0] ImmSrc);
    // better to use a case as optimizing this by hand
    // (if I wanted to add extra ALU ops)
    // would be redundant
always_comb  
    case(op)
    // lw (
    7'b0000_011: ImmSrc = 2'b00;
    // sw 
    7'b0100_011: ImmSrc = 2'b01;
    // R-type
    7'b0110_011: ImmSrc = 2'b00;
    // beq
    7'b1100_011: ImmSrc = 2'b10;
    // addi
    7'b0010_011: ImmSrc = 2'b00;
    // jal
    7'b1101_111: ImmSrc = 2'b11;
    default: ImmSrc = 2'bxx;
    endcase
endmodule


module testbench2();

  logic        clk;
  logic        reset;
  
  opcodetype  op;
  logic [2:0] funct3;
  logic       funct7b5;
  logic       Zero;
  logic [1:0] ImmSrc;
  logic [1:0] ALUSrcA, ALUSrcB;
  logic [1:0] ResultSrc;
  logic       AdrSrc;
  logic [2:0] ALUControl;
  logic       IRWrite, PCWrite;
  logic       RegWrite, MemWrite;
  
  logic [31:0] vectornum, errors;
  logic [39:0] testvectors[10000:0];
  
  logic        new_error;
  logic [15:0] expected;
  logic [6:0]  hash;


  // instantiate device to be tested
  controller dut(clk, reset, op, funct3, funct7b5, Zero,
                 ImmSrc, ALUSrcA, ALUSrcB, ResultSrc, AdrSrc, ALUControl, IRWrite, PCWrite, RegWrite, MemWrite);
  
  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors and pulse reset
  initial
    begin
      $readmemb("controller.tv", testvectors);
      vectornum = 0; errors = 0; hash = 0;
      reset = 1; #22; reset = 0;
    end
	 
  // apply test vectors on rising edge of clk
  always @(posedge clk)
    begin
      #1; {op, funct3, funct7b5, Zero, expected} = testvectors[vectornum];
    end

  // check results on falling edge of clk
  always @(negedge clk)
    if (~reset) begin // skip cycles during reset
      new_error=0; 

      if ((ImmSrc!==expected[15:14])&&(expected[15:14]!==2'bxx))  begin
        $display("   ImmSrc = %b      Expected %b", ImmSrc,     expected[15:14]);
        new_error=1;
      end
      if ((ALUSrcA!==expected[13:12])&&(expected[13:12]!==2'bxx)) begin
        $display("   ALUSrcA = %b     Expected %b", ALUSrcA,    expected[13:12]);
        new_error=1;
      end
      if ((ALUSrcB!==expected[11:10])&&(expected[11:10]!==2'bxx)) begin
        $display("   ALUSrcB = %b     Expected %b", ALUSrcB,    expected[11:10]);
        new_error=1;
      end
      if ((ResultSrc!==expected[9:8])&&(expected[9:8]!==2'bxx))   begin
        $display("   ResultSrc = %b   Expected %b", ResultSrc,  expected[9:8]);
        new_error=1;
      end
      if ((AdrSrc!==expected[7])&&(expected[7]!==1'bx))           begin
        $display("   AdrSrc = %b       Expected %b", AdrSrc,     expected[7]);
        new_error=1;
      end
      if ((ALUControl!==expected[6:4])&&(expected[6:4]!==3'bxxx)) begin
        $display("   ALUControl = %b Expected %b", ALUControl, expected[6:4]);
        new_error=1;
      end
      if ((IRWrite!==expected[3])&&(expected[3]!==1'bx))          begin
        $display("   IRWrite = %b      Expected %b", IRWrite,    expected[3]);
        new_error=1;
      end
      if ((PCWrite!==expected[2])&&(expected[2]!==1'bx))          begin
        $display("   PCWrite = %b      Expected %b", PCWrite,    expected[2]);
        new_error=1;
      end
      if ((RegWrite!==expected[1])&&(expected[1]!==1'bx))         begin
        $display("   RegWrite = %b     Expected %b", RegWrite,   expected[1]);
        new_error=1;
      end
      if ((MemWrite!==expected[0])&&(expected[0]!==1'bx))         begin
        $display("   MemWrite = %b     Expected %b", MemWrite,   expected[0]);
        new_error=1;
      end

      if (new_error) begin
        $display("Error on vector %d: inputs: op = %h funct3 = %h funct7b5 = %h", vectornum, op, funct3, funct7b5);
        errors = errors + 1;
      end
      vectornum = vectornum + 1;
      hash = hash ^ {ImmSrc&{2{expected[15:14]!==2'bxx}}, ALUSrcA&{2{expected[13:12]!==2'bxx}}} ^ {ALUSrcB&{2{expected[11:10]!==2'bxx}}, ResultSrc&{2{expected[9:8]!==2'bxx}}} ^ {AdrSrc&{expected[7]!==1'bx}, ALUControl&{3{expected[6:4]!==3'bxxx}}} ^ {IRWrite&{expected[3]!==1'bx}, PCWrite&{expected[2]!==1'bx}, RegWrite&{expected[1]!==1'bx}, MemWrite&{expected[0]!==1'bx}};
      hash = {hash[5:0], hash[6] ^ hash[5]};
      if (testvectors[vectornum] === 40'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors);
	      $display("hash = %h", hash);
        $stop;
      end
    end
endmodule
