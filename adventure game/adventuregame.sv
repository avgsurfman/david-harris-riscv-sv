module roomfsm(input logic clk, reset,
               input logic n, s, e, w, sword, 
               output logic secret_stash, win, die);
    typedef enum logic [2:0] { cavedCacophony = 3'b000,
                               twistedTunnel = 3'b001,
                               rapidRiver = 3'b010,
                               secretSwordStash = 3'b011,
                               dragonsDen = 3'b100,
                               greviousGraveyard = 3'b101,
                               victoryVault = 3'b110
                              } statetype;
    statetype state, nextstate;

always_ff @(posedge clk, posedge reset)
    if(reset) state <= cavedCacophony;
    else      state <= nextstate;

always_comb 
    case(state)
        cavedCacophony:
        if(e) nextstate = twistedTunnel;
        else nextstate = cavedCacophony;
        twistedTunnel:
        if(s) nextstate = rapidRiver;
        else if(w) nextstate = cavedCacophony;
        else nextstate = twistedTunnel;
        rapidRiver:
        if(e) nextstate = dragonsDen;
        else if(w) nextstate = secretSwordStash;
        else if(n) nextstate = twistedTunnel;
        else nextstate = rapidRiver;
        secretSwordStash:
        if(e) nextstate = rapidRiver;
        else nextstate = secretSwordStash;
        dragonsDen:
        if(sword) nextstate = victoryVault;
        else nextstate = greviousGraveyard;
        victoryVault: nextstate = victoryVault;
        greviousGraveyard: nextstate = greviousGraveyard;
        default: nextstate = cavedCacophony; 
          
     endcase

assign win = ( state == victoryVault);
assign die = ( state == greviousGraveyard);
assign secret_stash = ( state == secretSwordStash);

endmodule


module swordfsm(input logic clk, reset, secret_stash,
                output logic sword);

typedef enum logic { noSword = 1'b0, 
                    gotSword = 1'b1} statetype;

statetype state, nextstate;

always_ff @(posedge clk, posedge reset)
    if(reset) state <= noSword;
    else      state <= nextstate;

always_comb
   case(state)
       noSword:
       if(secret_stash) nextstate = gotSword;
       else nextstate = noSword;
       gotSword: nextstate = gotSword;
   endcase

assign sword = (state == gotSword);

endmodule


module adventuregame(input  logic clk, reset,
                     input  logic n, s, e, w,
                     output logic win, die);

logic secret_stash, sword;

roomfsm room(clk, reset, n, s, e, w, sword, secret_stash, win, die);
swordfsm igotdapowah(clk, reset, secret_stash, sword);

					
endmodule

module testbench(); 
  logic        clk, reset;
  logic        n, s, e, w, win, die, winexpected, dieexpected; //I EXPECT YOU to DIE
  logic [31:0] vectornum, errors;
  logic [5:0]  testvectors[10000:0];
  logic [6:0]  hash;

  // instantiate device under test 
  adventuregame  dut(clk, reset, n, s, e, w, win, die); 

  // generate clock 
  always 
    begin
      clk=1; #5; clk=0; #5; 
    end 

  // at start of test, load vectors 
  // and pulse reset
  initial 
    begin
      $readmemb("adventuregame.tv", testvectors); 
      vectornum = 0; errors = 0; hash = 0; reset = 1; #22; reset = 0; #70; reset = 1; #10; reset = 0;
    end 

  // apply test vectors on rising edge of clk 
  always @(posedge clk) 
    begin
      #1; {n, s, e, w, winexpected, dieexpected} = testvectors[vectornum]; 
    end 

  // check results on falling edge of clk 
  always @(negedge clk) 
    if (~reset) begin    // skip during reset
      if (win !== winexpected || die !== dieexpected) begin // check result 
        $display("Error: inputs = %b", {n, s, e, w});
        $display(" state = %b", dut.room.state);
        $display(" outputs = %b %b (%b %b expected)", 
                 win, die, winexpected, dieexpected); 
        errors = errors + 1; 
      end
      hash = hash ^ {win, die};
      hash = {hash[5:0], hash[6]^hash[5]};
      vectornum = vectornum + 1;
      if (testvectors[vectornum] === 6'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors); 
        $display("hash: %h", hash);
        $stop; 
      end 
    end 
endmodule 

