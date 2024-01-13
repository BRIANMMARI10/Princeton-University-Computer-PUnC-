//==============================================================================
// Control Unit for PUnC LC3 Processor
//==============================================================================

`include "Defines.v"

module PUnCControl(
	// External Inputs
	input  wire        clk,            // Clock
	input  wire        rst,            // Reset

	// output to datapath
	output reg pc_inc,
	output reg pc_w_en,
	output reg pc_clr,

	output reg ir_w_en,

	output reg [15:0] mem_r_addr_ctrl,
	output reg [1:0] mem_r_s,
	output reg [1:0] mem_w_addr_s,
	output reg [1:0] mem_w_data_s,
	output reg mem_w_en,

	output reg [4:0] alu_s,

	output reg rf_w_en,
	output reg [1:0] rf_w_s,
	output reg [2:0] rf_w_addr,
	output reg [15:0] rf_w_data_ctrl,
	output reg [2:0] rf_r0_addr,
	output reg [2:0] rf_r1_addr,

	output reg status_w_en,

	// inputs from datapath
	input [15:0] pc,
	input [15:0] ir
);
	// FSM States
	//Add your FSM State values as localparams here
	localparam STATE_FETCH = 5'd0;
	localparam STATE_DECODE = 5'd1;
	localparam STATE_ADD = 5'd2;
	localparam STATE_AND = 5'd3;
	localparam STATE_BR = 5'd4;
	localparam STATE_JMP_RET = 5'd5;
	localparam STATE_JSR_JSRR = 5'd6;
	localparam STATE_LD = 5'd17; //forgot this one
	localparam STATE_LDI1 = 5'd7;
	localparam STATE_LDI2 = 5'd8;
	localparam STATE_LDR = 5'd9;
	localparam STATE_LEA = 5'd10;
	localparam STATE_NOT = 5'd11;
	localparam STATE_ST = 5'd12;
	localparam STATE_STI1 = 5'd13;
	localparam STATE_STI2 = 5'd14;
	localparam STATE_STR = 5'd15;
	localparam STATE_HALT = 5'd16;

	// State, Next State
	reg [4:0] state, next_state;

	// Output Combinational Logic
	always @( * ) begin
		// Set default values for outputs here (prevents implicit latching)
		pc_inc = 0;
		pc_w_en = 0;
		mem_w_en = 0;
		ir_w_en = 0;
		status_w_en = 0;
		rf_w_en = 0;

		// Add your output logic here
		case (state)
			STATE_FETCH: begin
				pc_clr = 0;
				mem_r_addr_ctrl = pc;
				mem_r_s = `MEM_R_CTRL;
				ir_w_en = 1;
			end
			STATE_DECODE: begin
				pc_inc = 1;
			end
			STATE_ADD: begin
				status_w_en = 1;
				// write to R[DR] from ALU (SR1 + SR2 or SR1 + sext_imm5)
				rf_w_en = 1;
				rf_w_addr = `DR;
				rf_w_s = `RF_W_ALU;
				
				rf_r0_addr = `SR1;
				rf_r1_addr = `SR2;
				
				if (ir[5] == 0) begin
					alu_s = `ALU_ADD;
				end
				else begin
					alu_s = `ALU_ADDI;
				end
			end
			STATE_AND: begin
				status_w_en = 1;
				// write to R[DR] from ALU (SR1 & SR2 or SR1 & sext_imm5)
				rf_w_en = 1;
				rf_w_addr = `DR;
				rf_w_s = `RF_W_ALU;
				
				rf_r0_addr = `SR1;
				rf_r1_addr = `SR2;

				if (ir[5] == 0) begin
					alu_s = `ALU_AND;
				end
				else begin
					alu_s = `ALU_ANDI;
				end
			end
			STATE_BR: begin
				// write to PC from ALU (PC + sext_PCOffset9)
				pc_w_en = 1;
				alu_s = `ALU_BR;
			end
			STATE_JMP_RET: begin
				// write to PC from ALU (BaseR)
				pc_w_en = 1;
				alu_s = `ALU_JMP_RET;
				rf_r0_addr = `BaseR;
			end
			STATE_JSR_JSRR: begin
				// write to PC from ALU (BaseR or PC+sext_PCOffset11)
				rf_w_en = 1;
				rf_w_s = `RF_W_PC;
				rf_w_addr = 3'd7;

				pc_w_en = 1;
				rf_r0_addr = `BaseR;

				if (ir[11] == 1) begin
					alu_s = `ALU_JSR;
				end
				else begin
					alu_s = `ALU_JSRR;
				end
			end
			STATE_LD: begin
				status_w_en = 1;
				// write to R[DR] from memory[of ALU (PC+sext_PCOffset9)]
				rf_w_en = 1;
				rf_w_addr = `DR;
				rf_w_s = `RF_W_MEM;

				mem_r_s = `MEM_R_ALU;
				
				alu_s = `ALU_LD;
			end
			STATE_LDI1: begin
				// write to R[DR] from memory[of ALU (PC+sext_PCOffset9)]
				rf_w_en = 1;
				rf_w_addr = `DR;
				rf_w_s = `RF_W_MEM;

				mem_r_s = `MEM_R_ALU;
				
				alu_s = `ALU_LDI1; //outputs (PC+sext_PCOffset9)
			end
			STATE_LDI2: begin
				status_w_en = 1;
				// write to R[DR] from memory[R[DR]]
				rf_w_en = 1;
				rf_w_addr = `DR;
				rf_w_s = `RF_W_MEM;
				rf_r0_addr = `DR;

				mem_r_s = `MEM_R_ALU;
				
				alu_s = `ALU_LDI2; // outputs R[DR]
			end
			STATE_LDR: begin
				status_w_en = 1;
				// write to R[DR] from memory[of ALU (BaseR+sext_offset6)]
				rf_w_en = 1;
				rf_w_addr = `DR;
				rf_w_s = `RF_W_MEM;
				rf_r0_addr = `BaseR;

				mem_r_s = `MEM_R_ALU;
				
				alu_s = `ALU_LDR; // outputs BaseR+sext_offset6
			end
			STATE_LEA: begin
				status_w_en = 1;
				// write to R[DR] from ALU (PC+sext_PCoffset9)
				rf_w_en = 1;
				rf_w_addr = `DR;
				rf_w_s = `RF_W_ALU;
				
				alu_s = `ALU_LEA; // outputs PC+sext_PCoffset9
			end
			STATE_NOT: begin
				status_w_en = 1;
				// write to R[DR] from ALU (not(SR))
				rf_w_en = 1;
				rf_w_addr = `DR;
				rf_w_s = `RF_W_ALU;

				rf_r0_addr = `SR1;
				alu_s = `ALU_NOT;
			end
			STATE_ST: begin
				// write to mem[of ALU (PC+sext_PCoffset9)] from ST_SR
				mem_w_en = 1;
				mem_w_addr_s = `MEM_W_ADDR_ALU;

				rf_r0_addr = `ST_SR;
				mem_w_data_s = `MEM_W_DATA_R0;

				alu_s = `ALU_ST;
			end
			STATE_STI1: begin
				// reading from mem[of ALU (PC+sext_PCoffset9)]
				mem_r_s = `MEM_R_ALU;
				alu_s = `ALU_STI1;
			end
			STATE_STI2: begin
				// write to mem[from STI1 (mem[PC+sext_PCoffset9] from ST_SR
				mem_w_en = 1;
				mem_w_addr_s = `MEM_W_ADDR_SELF;

				rf_r0_addr = `ST_SR;
				mem_w_data_s = `MEM_W_DATA_R0;
			end
			STATE_STR: begin
				// write to mem[of ALU (BaseR+sext_Poffset6)] from ST_SR
				mem_w_en = 1;
				mem_w_addr_s = `MEM_W_ADDR_ALU;

				rf_r0_addr = `ST_SR;
				mem_w_data_s = `MEM_W_DATA_R0;

				rf_r1_addr = `BaseR;
				alu_s = `ALU_STR;
			end
			STATE_HALT: begin
				
			end
		endcase
	end

	// Next State Combinational Logic
	always @( * ) begin
		// Set default value for next state here
		next_state = state;

		// Add your next-state logic here
		case (state)
			STATE_FETCH: begin
				next_state = STATE_DECODE;
			end
			STATE_DECODE: begin
				case (`opcode)
					`OC_ADD: begin
						next_state = STATE_ADD;
					end
					`OC_AND: begin
						next_state = STATE_AND;
					end
					`OC_BR: begin
						next_state = STATE_BR;
					end
					`OC_JMP: begin
						next_state = STATE_JMP_RET;
					end
					`OC_JSR: begin
						next_state = STATE_JSR_JSRR;
					end
					`OC_LD: begin
						next_state = STATE_LD;
					end
					`OC_LDI: begin
						next_state = STATE_LDI1;
					end
					`OC_LDR: begin
						next_state = STATE_LDR;
					end
					`OC_LEA: begin
						next_state = STATE_LEA;
					end
					`OC_NOT: begin
						next_state = STATE_NOT;
					end
					`OC_ST: begin
						next_state = STATE_ST;
					end
					`OC_STI: begin
						next_state = STATE_STI1;
					end
					`OC_STR: begin
						next_state = STATE_STR;
					end
					`OC_HLT: begin
						next_state = STATE_HALT;
					end
				endcase
			end
			STATE_ADD: begin
				next_state = STATE_FETCH;
			end
			STATE_AND: begin
				next_state = STATE_FETCH;
			end
			STATE_BR: begin
				next_state = STATE_FETCH;
			end
			STATE_JMP_RET: begin
				next_state = STATE_FETCH;
			end
			STATE_JSR_JSRR: begin
				next_state = STATE_FETCH;
			end
			STATE_LD: begin
				next_state = STATE_FETCH;
			end
			STATE_LDI1: begin
				next_state = STATE_LDI2;
			end
			STATE_LDI2: begin
				next_state = STATE_FETCH;
			end
			STATE_LDR: begin
				next_state = STATE_FETCH;
			end
			STATE_LEA: begin
				next_state = STATE_FETCH;
			end
			STATE_NOT: begin
				next_state = STATE_FETCH;
			end
			STATE_ST: begin
				next_state = STATE_FETCH;
			end
			STATE_STI1: begin
				next_state = STATE_STI2;
			end
			STATE_STI2: begin
				next_state = STATE_FETCH;
			end
			STATE_STR: begin
				next_state = STATE_FETCH;
			end
			STATE_HALT: begin
				next_state = STATE_HALT;
			end
		endcase
	end

	// State Update Sequential Logic
	always @(posedge clk) begin
		if (rst) begin
			// Add your initial state here
			state <= STATE_FETCH;
			pc_clr <= 1;
		end
		else begin
			// Add your next state here
			state <= next_state;
		end
	end

endmodule
