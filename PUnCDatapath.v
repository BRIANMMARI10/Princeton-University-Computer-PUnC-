//==============================================================================
// Datapath for PUnC LC3 Processor
//==============================================================================

`include "Memory.v"
`include "RegisterFile.v"
`include "Defines.v"

module PUnCDatapath(
	// External Inputs
	input  wire        clk,            // Clock
	input  wire        rst,            // Reset

	// DEBUG Signals
	input  wire [15:0] mem_debug_addr,
	input  wire [2:0]  rf_debug_addr,
	output wire [15:0] mem_debug_data,
	output wire [15:0] rf_debug_data,
	output wire [15:0] pc_debug_data,

	// Input from controller
	input pc_inc,	
	input pc_clr,
	input pc_w_en,

	input ir_w_en,

	input [15:0] mem_r_addr_ctrl,
	input [1:0] mem_r_s,
	input [1:0] mem_w_addr_s,
	input [1:0] mem_w_data_s,
	input mem_w_en,

	input [4:0] alu_s,

	input rf_w_en,
	input [1:0] rf_w_s,
	input [2:0] rf_w_addr,
	input [15:0] rf_w_data_ctrl,
	input [2:0] rf_r0_addr,
	input [2:0] rf_r1_addr,

	input status_w_en,

	// Output to controller
	output [15:0] pc,
	output [15:0] ir
);
	// Local Registers
	reg [15:0] pc;
	reg [15:0] ir;
	reg[15:0] pc_w_data;

	reg n, z, p;

	reg [15:0] rf_w_data;
	wire [15:0] rf_r0_data;
	wire [15:0] rf_r1_data;

	reg [15:0] mem_w_addr;
	reg [15:0] mem_w_data;
	reg [15:0] mem_r_addr;
	wire [15:0] mem_r_data;

	reg [15:0] alu_output;

	// Assign PC debug net
	assign pc_debug_data = pc;

	always @(posedge clk) begin
		if (pc_inc) begin
			pc <= pc + 1;
		end
		if (pc_w_en) begin
			pc <= pc_w_data;
		end
		if (pc_clr || rst) begin
			pc <= 16'd0;
		end
		
		if (ir_w_en) begin
			ir <= mem_r_data;
		end

		if (status_w_en) begin
			if (rf_w_data == 16'd0) begin
				n<=0; 
				z<=1; 
				p<=0;
			end
			else if (rf_w_data[15]) begin
				n<=1; 
				z<=0; 
				p<=0;
			end
			else begin
				n<=0; 
				z<=0; 
				p<=1;
			end
		end
	end

	always @( * ) begin
		case (alu_s)
			`ALU_ADD: begin
				alu_output = rf_r0_data + rf_r1_data;
			end
			`ALU_ADDI: begin
				alu_output = rf_r0_data + `sext_imm5;
			end
			`ALU_AND: begin
				alu_output = rf_r0_data & rf_r1_data;
			end
			`ALU_ANDI: begin
				alu_output = rf_r0_data & `sext_imm5;
			end
			`ALU_BR: begin
				if ((`ir_n && n) || (`ir_z && z) || (`ir_p && p)) begin
					alu_output = pc + `sext_PCoffset9;
				end
				else begin
					alu_output = pc;
				end
			end
			`ALU_JMP_RET: begin
				alu_output = rf_r0_data; //baseR
			end
			`ALU_JSR: begin
				alu_output = pc + `sext_PCoffset11;
			end
			`ALU_JSRR: begin
				alu_output = rf_r0_data; //baseR
			end
			`ALU_LD: begin
				alu_output = pc + `sext_PCoffset9;
			end
			`ALU_LDI1: begin
				alu_output = pc + `sext_PCoffset9;
			end
			`ALU_LDI2: begin
				alu_output = rf_r0_data;
			end
			`ALU_LDR: begin
				alu_output = rf_r0_data + `sext_offset6;
			end
			`ALU_LEA: begin
				alu_output = pc + `sext_PCoffset9;
			end
			`ALU_NOT: begin
				alu_output = ~rf_r0_data;
			end
			`ALU_ST: begin
				alu_output = pc + `sext_PCoffset9;
			end
			`ALU_STI1: begin
				alu_output = pc + `sext_PCoffset9;
			end
			`ALU_STI2: begin
				//nothing!
			end
			`ALU_STR: begin
				alu_output = rf_r1_data + `sext_offset6;
			end
		endcase

		case (mem_r_s)
			`MEM_R_ALU: begin
				mem_r_addr = alu_output;
			end
			`MEM_R_CTRL: begin
				mem_r_addr = mem_r_addr_ctrl;
			end
		endcase

		case (rf_w_s)
			`RF_W_ALU: begin
				rf_w_data = alu_output;
			end
			`RF_W_CNTRL: begin
				rf_w_data = rf_w_data_ctrl;
			end
			`RF_W_PC: begin
				rf_w_data = pc;
			end
			`RF_W_MEM: begin
				rf_w_data = mem_r_data;
			end
		endcase

		case (mem_w_addr_s)
			`MEM_W_ADDR_ALU: begin
				mem_w_addr = alu_output;
			end
			`MEM_W_ADDR_SELF: begin
				mem_w_addr = mem_r_data;
			end
		endcase

		case (mem_w_data_s)
			`MEM_W_DATA_R0: begin
				mem_w_data = rf_r0_data;
			end
			`MEM_W_DATA_R1: begin
				mem_w_addr = rf_r1_data;
			end
		endcase

		pc_w_data = alu_output; // will only get stored if pc_w_en == 1
	end

	//----------------------------------------------------------------------
	// Memory Module
	//----------------------------------------------------------------------

	// 1024-entry 16-bit memory (connect other ports)
	Memory mem(
		.clk      (clk),
		.rst      (rst),
		.r_addr_0 (mem_r_addr),
		.r_addr_1 (mem_debug_addr),
		.w_addr   (mem_w_addr),
		.w_data   (mem_w_data),
		.w_en     (mem_w_en),
		.r_data_0 (mem_r_data),
		.r_data_1 (mem_debug_data)
	);

	//----------------------------------------------------------------------
	// Register File Module
	//----------------------------------------------------------------------

	// 8-entry 16-bit register file (connect other ports)
	RegisterFile rfile(
		.clk      (clk),
		.rst      (rst),
		.r_addr_0 (rf_r0_addr),
		.r_addr_1 (rf_r1_addr),
		.r_addr_2 (rf_debug_addr),
		.w_addr   (rf_w_addr),
		.w_data   (rf_w_data),
		.w_en     (rf_w_en),
		.r_data_0 (rf_r0_data),
		.r_data_1 (rf_r1_data),
		.r_data_2 (rf_debug_data)
	);

	//----------------------------------------------------------------------
	// Add all other datapath logic here
	//----------------------------------------------------------------------

endmodule
