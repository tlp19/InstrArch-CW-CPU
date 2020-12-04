module CPU_MIPS_harvard(
	input logic clk, reset,
	output logic active,
	output logic [31:0] register_v0,
	
	input logic clk_enable,
	
	output logic [31:0] instr_address,	//PC Next
	input logic [31:0] instr_readdata,	//Data stored at address determined by PCnext
	
	output logic [31:0] data_address,		//ALU_result
	output logic data_write,				//control signal Data memory write enable for data
	output logic data_read,
	output logic [31:0] data_writedata,
	input logic [31:0] data_readdata);
	
logic memtoreg1, memtoreg2, branch, alusrc, regdst1, regdst2, regwrite, jump1, jump, zero, pcsrc, pc;
logic [4:0] alucontrol;

controller control(instr_readdata[31:26], instr_readdata[5:0], instr_readdata[20:16], zero, memtoreg1, memtoreg1, data_write, pcsrc, alusrc, regdst2, regdst1, regwrite, jump1, jump, alucontrol);

datapath datap(clk, reset, clk_enable, memtoreg2, memtoreg1, alusrc, pcsrc, regdst2, regdst1, regwrite, jump1, jump, alucontrol, zero, pc, instr_readdata, data_readdata, data_address, data_writedata, instr_address[25:0]);

endmodule

module controller(
	input logic [5:0] op, funct,
	input logic [4:0] dest,
	input logic zero,
	output logic memtoreg2, memtoreg1,
	output logic pcsrc, alusrc,
	output logic regdst2, regdst1,
	output logic regwrite, data_write,
	output logic jump1, jump,
	output logic [4:0] alucontrol);
	
logic [1:0] aluop;
logic branch;

maindec md(op, funct, dest, memtoreg2, memtoreg1, data_write, branch, alusrc, regdst2, regdst1, regwrite, jump1, jump, aluop);

aludec ad(funct, op, dest, aluop, alucontrol);
	always @(*) begin
		assign pcsrc = branch & zero;
	end
endmodule

module maindec(
	input logic [5:0] op, funct,
	input logic [4:0] dest,
	output logic memtoreg2, memtoreg1, data_write,
	output logic branch, alusrc,
	output logic regdst2, regdst1,
	output logic regwrite,
	output logic jump1, jump,
	output logic [1:0] aluop);
	
	
reg [10:0] controls;


//Probably needs to use a always@(*)

assign {regwrite, regdst2, regdst1, alusrc, branch, data_write, memtoreg2, memtoreg1, jump, aluop} = controls;


// Assign 11 elements names as aluop consist of 2 bits so rightfully fills the reg controls.
// Correspond to the bits below from left to right in the same order (starting with regwrite and ending with aluop).


always @(*)
	case(op)
		6'b000000: case(funct)									//link in reg not $31
						6'b001001: begin 						//Jump and link register
									controls <= 11'b10000000100;
									jump1 = 1;
								end
						6'b001000: begin						//Jump register
									controls = 11'b00100000110; 
									jump1 = 1;
								end
						6'b010001: controls = 11'b10000000010; //Move to high       No need to write enable register?
						6'b010100: controls = 11'b10000000010; //Move to low		  As HI and LO are reg in ALU module
						default: controls = 11'b10100000010; //R-type instruction
					endcase
		6'b100000: controls = 11'b10010001000; //Load byte
		6'b100100: controls = 11'b10010001000; //Load byte unsigned
		6'b100001: controls = 11'b10010001000; //Load halfword
		6'b100101: controls = 11'b10010001000; //Load halfword unisigned
		6'b001111: controls = 11'b10010001000; //Load upper immidiate
		6'b100011: controls = 11'b10010001000; //Load word
		6'b100010: controls = 11'b10010001000; //Load word left
		6'b100110: controls = 11'b10010001000; //Load word right
		6'b101000: controls = 11'b00010100000; //Store byte
		6'b101001: controls = 11'b00010100000; //Store halfword
		6'b101011: controls = 11'b00010100000; //Store word
		6'b000100: controls = 11'b00001000001; //Branch on = 0
		6'b000001: case(dest)
						5'b00001: controls = 11'b00001000001; //Branch on >= 0
						5'b10001: controls = 11'b11001010001; //Branch on >= 0 /link (regwrite active)
						5'b00000: controls = 11'b00001000001; //Branch on < 0
						5'b10000: controls = 11'b11001010001; //Branch on < 0 /link
						default:  controls = 11'bxxxxxxxxxxx;
					endcase
		6'b000111: controls = 11'b00001000001; //Branch on > 0
		6'b000110: controls = 11'b00001000001; //Branch on = 0
		6'b000101: controls = 11'b00001000001; //Branch on != 0
		6'b001001: controls = 11'b10010000010; //ADD unsigned immediate
		6'b000010: controls = 11'b00000000100; //Jump
		6'b000011: controls = 11'b11000010100; //Jump and link
		6'b001100: controls = 11'b10010000010; //ANDI
		6'b001101: controls = 11'b10010000010; //ORI
		6'b001110: controls = 11'b10010000010; //XORI
		6'b001010: controls = 11'b10010000010; //Set on less than immediate (signed)
		6'b001011: controls = 11'b10010000010; //Set on less than immediate unsigned
		default:   controls = 11'bxxxxxxxxxxx; //???
	endcase
endmodule


// We are currently setting all the control signals by looking at the opcode of the instrunctions
// We created an reg (=array) of control signals so that it is easier to implement.
// In order to understand this section please refer to page 376 of the book (table 7.3)



module aludec(
	input logic [5:0] funct,op,
	input logic [4:0] dest,
	input logic [1:0] aluop,
	output logic [4:0] alucontrol);

always @(*)
	case(aluop)							//edge what if we have a 2'b11 eventhough it is illegal
	
		2'b00: alucontrol = 5'b00011; //ADD -- USED FOR LOAD AND STORE INSTRUCTIONS
		2'b01: alucontrol = 5'b00100; //SUB 
		2'b10: case(op)
/*			6'b100000: alucontrol = 5'b; //Load byte				
			6'b100100: alucontrol = 5'b; //Load byte unsigned
			6'b100001: alucontrol = 5'b; //Load halfword			
			6'b100101: alucontrol = 5'b; //Load halfword unsigned
			6'b001111: alucontrol = 5'b; //Load upper immidiate
			6'b100011: alucontrol = 5'b; //Load word
			6'b100010: alucontrol = 5'b; //Load word left         
			6'b100110: alucontrol = 5'b; //Load word right
			6'b101000: alucontrol = 5'b; //Store byte
			6'b101001: alucontrol = 5'b; //Store halfword
			6'b101011: alucontrol = 5'b; //Store word
*/			
			6'b000100: alucontrol = 5'b00100; //Branch on = 0 use SUBU
			6'b000001: case(dest)
						5'b00001: alucontrol = 5'b00110; //Branch on >= 0 use SLT
						5'b10001: alucontrol = 5'b00110; //Branch on >= 0 /link (regwrite active) use SLT mod in control sign
						5'b00000: alucontrol = 5'b10011; //Branch on < 0 
						5'b10000: alucontrol = 5'b10100; //Branch on < 0 /link
						default: alucontrol = 5'bxxxxx;
					endcase
			6'b000111: alucontrol = 5'b10101; //Branch on > 0
			6'b000110: alucontrol = 5'b10110; //Branch on = 0
			6'b000101: alucontrol = 5'b10111; //Branch on != 0
			6'b001001: alucontrol = 5'b00011; //ADD unsigned immediate
			6'b000010: alucontrol = 5'b; //Jump
			6'b000011: alucontrol = 5'b; //Jump and link
			6'b001100: alucontrol = 5'b00000; //ANDI
			6'b001101: alucontrol = 5'b00001; //ORI
			6'b001110: alucontrol = 5'b00010; //XORI
			6'b001010: alucontrol = 5'b00110; //Set on less than immediate (signed)
			6'b001011: alucontrol = 5'b00101; //Set on less than immediate unsigned
			
			6'b000000: case(funct)
							6'b100001: alucontrol = 5'b00011; //ADD -> ADDU
							6'b100100: alucontrol = 5'b00000; //AND -> AND
							6'b100011: alucontrol = 5'b00100; //SUB unsigned -> SUBU
							6'b100101: alucontrol = 5'b00001; //bitwise OR -> OR
							6'b100110: alucontrol = 5'b00010; //bitwise XOR -> XOR
							6'b101010: alucontrol = 5'b00110; //SLT -> SLT
							6'b101011: alucontrol = 5'b00101; //SLTUnsigned -> SLTU
							6'b011001: alucontrol = 5'b00111; //Multiply unsigned -> MULTU
							6'b011000: alucontrol = 5'b01000; //Multiply -> MULT
							6'b000000: alucontrol = 5'b01001; //Shift left logical ->SLL
							6'b000100: alucontrol = 5'b01010; //Shift left logical variable -> SLLV
							6'b000011: alucontrol = 5'b01011; //Shift right arithmetic -> SRA
							6'b000010: alucontrol = 5'b01100; //Shift right logical -> SRL
							6'b000111: alucontrol = 5'b01101; //Shift right arithmetic variable -> SRAV
							6'b000110: alucontrol = 5'b01110; //Shift right logical variable -> SRLV
							6'b011010: alucontrol = 5'b01111; //Divide signed DIV
							6'b011011: alucontrol = 5'b10000; //Divide unsigned DIVU
							6'b010001: alucontrol = 5'b10001; //MTHI
							6'b010100: alucontrol = 5'b10010; //MTLO
							6'b001000: alucontrol = 5'b11001; //Jump register JR
							6'b001001: alucontrol = 5'b00000; //Jump and link register
							default:   alucontrol = 5'bxxxxx; //???
						endcase
			default: alucontrol = 5'bxxxxx; //???		
			endcase	
	endcase
endmodule


// In this module we are setting the control signals for the ALU. Refer to the table 7.2 page 376.
// Note: The aluop can't be 2'b11. 
// The default: case(funct) replaces an iterative: 2'b10 & 5'bxxxxx (funct) 


module datapath(
	input logic clk, reset, clk_enable,
	input logic memtoreg2, memtoreg1,
	input logic alusrc, pcsrc,
	input logic regdst2, regdst1,
	input logic regwrite,
	input logic jump1, jump,
	input logic [4:0] alucontrol,
	output logic zero,
	output logic [31:0] pc,
	input logic [31:0] instr_readdata,
	input logic [31:0] data_readdata,
	output logic [31:0] data_address, data_writedata,
	output logic [25:0] instr_address);

logic [4:0] writereg1, writereg;
logic [31:0] pcnext, pcnextbr, pcplus4, pcbranch, pclink;
logic [31:0] signimm, signimmsh, pcnextbr1, pcnextbr2;
logic [31:0] srca, srcb;
logic [31:0] result1, result;

// Program counter regfile

flipflopr #(32) pcreg(clk, reset, clk_enable, pcnextbr, pcnext);

adder pcpl4(pcnext, 32'b100, pcplus4);

shiftleft2 immshift(signimm, signimmsh);

adder pcbr(signimmsh, pcplus4, pcbranch);

mux2 #(32) pcmux1(pcplus4, pcbranch, pcsrc, pcnextbr1);


mux2 #(32) pcmux2({6'b0,instr_address}, result, jump1, pcnextbr2);

mux2 #(32) pcmux(pcnextbr1, pcnextbr2, jump, pcnextbr);

//another mux ?

	
//Register file
regfile register(clk, regwrite, instr_address[25:21], instr_address[20:16], writereg, result, srca, data_writedata);

mux2 #(5) wrmux(instr_address[20:16], instr_address[15:11], regdst1, writereg1);
mux2 #(5) wrmux2(writereg1, 5'b11111, regdst2, writereg);

adder pcbrlink(pcplus4, 32'b100, pclink);

mux2 #(32) resmux(data_address, data_readdata, memtoreg1, result1);
mux2 #(32) resmux2(result1, pclink, memtoreg2, result);

signext se(instr_address[15:0], signimm); 

//ALU file
mux2 #(32) srcbmux(data_writedata, signimm, alusrc, srcb);

alumodule alu(alucontrol, srca, srcb, zero, data_address); 

endmodule




// Implementation of the register file
module regfile(
	input logic 		clk,
	input logic 		we3,
	input logic [4:0] ra1, ra2, wa3,
	input logic [31:0] wd3,
	output logic [31:0] rd1, rd2
	);
	
	reg[31:0] rf[31:0];
	//three ported register file
	//read two ports combinationally
	//write third port on rising edge of clock
	//register 0 hardwir3d to 0
	
	always @(posedge clk)
		if(we3) rf[wa3] <= wd3;
		
	assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
	assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule




// Implementation of reusable functions used in datapath

module mux2 #(parameter WIDTH =8)(
	input logic [WIDTH - 1:0] a, b,
	input logic s,
	output logic [WIDTH - 1:0] y);

	assign y = s ? a : b;
endmodule
	

module adder(
	input logic [31:0] a,b,
	output logic [31:0] y);

	assign y = a + b;
endmodule

module shiftleft2(
	input logic [31:0] a,
	output logic [31:0] y);

	assign y = {{a[29:0]} , 2'b00};
endmodule
	
module flipflopr #(parameter WIDTH =8)(
	input logic clk, reset, clk_enable,
	input logic [WIDTH-1:0] d,
	output logic [WIDTH-1:0] q);

	always @(posedge clk, posedge reset)
		if(reset) 				q <= 0;
		else if(clk_enable) 	q <= d;
endmodule 
	
module signext(
	input logic [15:0] instr_readdata,
	output logic [31:0] signimm);
	
	assign signimm = {{16{instr_readdata[15]}},instr_readdata};
endmodule
