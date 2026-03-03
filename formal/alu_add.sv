// alu_add_wrapper.sv — Formal proof for ALU correctness
// Proves all 10 ALU operations produce correct results

module alu_add_wrapper (
    input logic clk
);

    (* anyseq *) logic [31:0] a;
    (* anyseq *) logic [31:0] b;

    // --- ADD (op=0000) ---
    logic [31:0] add_result; logic add_zero;
    sisAlu u_add (.a(a), .b(b), .op(4'b0000), .result(add_result), .zero(add_zero));
    always @(*) begin
        assert (add_result == a + b);
        assert (add_zero == (add_result == 32'h0));
    end

    // --- SUB (op=1000) ---
    logic [31:0] sub_result; logic sub_zero;
    sisAlu u_sub (.a(a), .b(b), .op(4'b1000), .result(sub_result), .zero(sub_zero));
    always @(*) begin
        assert (sub_result == a - b);
        assert (sub_zero == (sub_result == 32'h0));
    end

    // --- SLL (op=0001) ---
    logic [31:0] sll_result; logic sll_zero;
    sisAlu u_sll (.a(a), .b(b), .op(4'b0001), .result(sll_result), .zero(sll_zero));
    always @(*) begin
        assert (sll_result == (a << b[4:0]));
        assert (sll_zero == (sll_result == 32'h0));
    end

    // --- SLT (op=0010) ---
    logic [31:0] slt_result; logic slt_zero;
    sisAlu u_slt (.a(a), .b(b), .op(4'b0010), .result(slt_result), .zero(slt_zero));
    always @(*) begin
        assert (slt_result == {31'b0, $signed(a) < $signed(b)});
        assert (slt_zero == (slt_result == 32'h0));
    end

    // --- SLTU (op=0011) ---
    logic [31:0] sltu_result; logic sltu_zero;
    sisAlu u_sltu (.a(a), .b(b), .op(4'b0011), .result(sltu_result), .zero(sltu_zero));
    always @(*) begin
        assert (sltu_result == {31'b0, a < b});
        assert (sltu_zero == (sltu_result == 32'h0));
    end

    // --- XOR (op=0100) ---
    logic [31:0] xor_result; logic xor_zero;
    sisAlu u_xor (.a(a), .b(b), .op(4'b0100), .result(xor_result), .zero(xor_zero));
    always @(*) begin
        assert (xor_result == (a ^ b));
        assert (xor_zero == (xor_result == 32'h0));
    end

    // --- SRL (op=0101) ---
    logic [31:0] srl_result; logic srl_zero;
    sisAlu u_srl (.a(a), .b(b), .op(4'b0101), .result(srl_result), .zero(srl_zero));
    always @(*) begin
        assert (srl_result == (a >> b[4:0]));
        assert (srl_zero == (srl_result == 32'h0));
    end

    // --- SRA (op=1101) ---
    logic [31:0] sra_result; logic sra_zero;
    sisAlu u_sra (.a(a), .b(b), .op(4'b1101), .result(sra_result), .zero(sra_zero));
    always @(*) begin
        assert (sra_result == $unsigned($signed(a) >>> b[4:0]));
        assert (sra_zero == (sra_result == 32'h0));
    end

    // --- OR (op=0110) ---
    logic [31:0] or_result; logic or_zero;
    sisAlu u_or (.a(a), .b(b), .op(4'b0110), .result(or_result), .zero(or_zero));
    always @(*) begin
        assert (or_result == (a | b));
        assert (or_zero == (or_result == 32'h0));
    end

    // --- AND (op=0111) ---
    logic [31:0] and_result; logic and_zero;
    sisAlu u_and (.a(a), .b(b), .op(4'b0111), .result(and_result), .zero(and_zero));
    always @(*) begin
        assert (and_result == (a & b));
        assert (and_zero == (and_result == 32'h0));
    end

endmodule
