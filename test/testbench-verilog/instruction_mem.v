module instruction_mem (
    input  logic [31:0] instr_address,  // = OFFSET + PC*4
    output logic [31:0] instr
);

  parameter INSTR_INIT_FILE = "";

  reg [31:0] imem[16777216];

  //initialization
  initial begin
    integer i;
    for (i = 0; i < 16777216; i++) begin
      $display("%d", i);
      imem[i] = 0;
    end

    if (INSTR_INIT_FILE != "") begin
      $readmemh(INSTR_INIT_FILE, imem);
    end
  end

  //making the async read
  always_comb begin
    instr = imem[instr_address];
  end
endmodule
