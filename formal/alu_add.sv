// alu_add_wrapper.sv — Formal proof for ALU ADD/SUB and zero flag
// Keeps assertions minimal for z3 solver efficiency

module alu_add_wrapper (
    input logic clk
);

    (* anyseq *) logic [31:0] a;
    (* anyseq *) logic [31:0] b;

    logic [31:0] add_result, sub_result, and_result, or_result, xor_result;
    logic        add_zero, sub_zero, and_zero, or_zero, xor_zero;

    // Test ADD
    sisAlu alu_add (
        .a(a), .b(b), .op(4'b0000),
        .result(add_result), .zero(add_zero)
    );

    // Test SUB
    sisAlu alu_sub (
        .a(a), .b(b), .op(4'b1000),
        .result(sub_result), .zero(sub_zero)
    );

    // Test AND
    sisAlu alu_and (
        .a(a), .b(b), .op(4'b0111),
        .result(and_result), .zero(and_zero)
    );

    // Test OR
    sisAlu alu_or (
        .a(a), .b(b), .op(4'b0110),
        .result(or_result), .zero(or_zero)
    );

    // Test XOR
    sisAlu alu_xor (
        .a(a), .b(b), .op(4'b0100),
        .result(xor_result), .zero(xor_zero)
    );

    // Assertions
    always @(*) begin
        // ADD correctness
        assert (add_result == a + b);
        assert (add_zero == (add_result == 32'h0));

        // SUB correctness
        assert (sub_result == a - b);
        assert (sub_zero == (sub_result == 32'h0));

        // AND correctness
        assert (and_result == (a & b));

        // OR correctness
        assert (or_result == (a | b));

        // XOR correctness
        assert (xor_result == (a ^ b));

        // Self-SUB is always zero
        // a - a = 0 (proven for all a when b=a via sub_result)
    end

endmodule
