// regfile_x0_wrapper.sv — Formal proof that x0 is always zero
// Uses SymbiYosys assertions

module regfile_x0_wrapper (
    input logic clk
);

    // Free (unconstrained) inputs
    (* anyseq *) logic [4:0]  rs1_addr;
    (* anyseq *) logic [4:0]  rs2_addr;
    (* anyseq *) logic        wr_en;
    (* anyseq *) logic [4:0]  rd_addr;
    (* anyseq *) logic [31:0] rd_data;

    logic [31:0] rs1_data, rs2_data;

    sisRegFile dut (
        .clk      (clk),
        .rs1_addr (rs1_addr),
        .rs1_data (rs1_data),
        .rs2_addr (rs2_addr),
        .rs2_data (rs2_data),
        .wr_en    (wr_en),
        .rd_addr  (rd_addr),
        .rd_data  (rd_data)
    );

    // Property: when reading x0, output is always 0
    always @(*) begin
        if (rs1_addr == 5'd0)
            assert (rs1_data == 32'h0);
        if (rs2_addr == 5'd0)
            assert (rs2_data == 32'h0);
    end

endmodule
