// sisAlu.sv — RV32I ALU (combinational)
// Supports all RV32I arithmetic/logic operations.

module sisAlu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  op,       // ALU operation select
    output logic [31:0] result,
    output logic        zero      // result == 0
);

  // ALU operation encoding
  localparam logic [3:0] ALU_ADD  = 4'b0000;
  localparam logic [3:0] ALU_SUB  = 4'b1000;
  localparam logic [3:0] ALU_SLL  = 4'b0001;
  localparam logic [3:0] ALU_SLT  = 4'b0010;
  localparam logic [3:0] ALU_SLTU = 4'b0011;
  localparam logic [3:0] ALU_XOR  = 4'b0100;
  localparam logic [3:0] ALU_SRL  = 4'b0101;
  localparam logic [3:0] ALU_SRA  = 4'b1101;
  localparam logic [3:0] ALU_OR   = 4'b0110;
  localparam logic [3:0] ALU_AND  = 4'b0111;

  always_comb begin
    case (op)
      ALU_ADD:  result = a + b;
      ALU_SUB:  result = a - b;
      ALU_SLL:  result = a << b[4:0];
      ALU_SLT:  result = {31'b0, $signed(a) < $signed(b)};
      ALU_SLTU: result = {31'b0, a < b};
      ALU_XOR:  result = a ^ b;
      ALU_SRL:  result = a >> b[4:0];
      ALU_SRA:  result = $unsigned($signed(a) >>> b[4:0]);
      ALU_OR:   result = a | b;
      ALU_AND:  result = a & b;
      default:  result = 32'h0;
    endcase
  end

  assign zero = (result == 32'h0);

endmodule
