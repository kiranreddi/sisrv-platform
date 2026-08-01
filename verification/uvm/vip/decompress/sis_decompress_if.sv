interface sis_decompress_if;
  logic [15:0] c_instr;
  logic [31:0] instr_o;
  logic        is_compressed_o;
  logic        illegal_o;
endinterface
