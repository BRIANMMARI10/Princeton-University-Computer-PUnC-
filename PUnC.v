//==============================================================================
// Module for PUnC LC3 Processor
//==============================================================================

`include "PUnCDatapath.v"
`include "PUnCControl.v"

module PUnC(
	// External Inputs
	input  wire        clk,            // Clock
	input  wire        rst,            // Reset

	// Debug Signals
	input  wire [15:0] mem_debug_addr,
	input  wire [2:0]  rf_debug_addr,
	output wire [15:0] mem_debug_data,
	output wire [15:0] rf_debug_data,
	output wire [15:0] pc_debug_data
);

	//----------------------------------------------------------------------
	// Interconnect Wires
	//----------------------------------------------------------------------

	wire pc_inc;
	wire pc_w_en;
	wire pc_clr;

	wire ir_w_en;

	wire [15:0] mem_r_addr_ctrl;
	wire [1:0] mem_r_s;
	wire [1:0] mem_w_addr_s;
	wire [1:0] mem_w_data_s;
	wire mem_w_en;

	wire [4:0] alu_s;

	wire rf_w_en;
	wire [1:0] rf_w_s;
	wire [2:0] rf_w_addr;
	wire [15:0] rf_w_data_ctrl;
	wire [2:0] rf_r0_addr;
	wire [2:0] rf_r1_addr;

	wire status_w_en;

	wire [15:0] pc;
	wire [15:0] ir;

	//----------------------------------------------------------------------
	// Control Module
	//----------------------------------------------------------------------
	PUnCControl ctrl(
		.clk             (clk),
		.rst             (rst),

		// Add more ports here
		.pc_inc(pc_inc),
		.pc_w_en(pc_w_en),
		.pc_clr(pc_clr),

		.ir_w_en(ir_w_en),

		.mem_r_addr_ctrl(mem_r_addr_ctrl),
		.mem_r_s(mem_r_s),
		.mem_w_addr_s(mem_w_addr_s),
		.mem_w_data_s(mem_w_data_s),
		.mem_w_en(mem_w_en),
		
		.alu_s(alu_s),

		.rf_w_en(rf_w_en),
		.rf_w_s(rf_w_s),
		.rf_w_addr(rf_w_addr),
		.rf_w_data_ctrl(rf_w_data_ctrl),
		.rf_r0_addr(rf_r0_addr),
		.rf_r1_addr(rf_r1_addr),

		.status_w_en(status_w_en),
		
		.pc(pc),
		.ir(ir)
	);

	//----------------------------------------------------------------------
	// Datapath Module
	//----------------------------------------------------------------------
	PUnCDatapath dpath(
		.clk             (clk),
		.rst             (rst),

		.mem_debug_addr   (mem_debug_addr),
		.rf_debug_addr    (rf_debug_addr),
		.mem_debug_data   (mem_debug_data),
		.rf_debug_data    (rf_debug_data),
		.pc_debug_data    (pc_debug_data),

		// Add more ports here
		.pc_inc(pc_inc),
		.pc_w_en(pc_w_en),
		.pc_clr(pc_clr),

		.ir_w_en(ir_w_en),

		.mem_r_addr_ctrl(mem_r_addr_ctrl),
		.mem_r_s(mem_r_s),
		.mem_w_addr_s(mem_w_addr_s),
		.mem_w_data_s(mem_w_data_s),
		.mem_w_en(mem_w_en),
		
		.alu_s(alu_s),

		.rf_w_en(rf_w_en),
		.rf_w_s(rf_w_s),
		.rf_w_addr(rf_w_addr),
		.rf_w_data_ctrl(rf_w_data_ctrl),
		.rf_r0_addr(rf_r0_addr),
		.rf_r1_addr(rf_r1_addr),

		.status_w_en(status_w_en),
		
		.pc(pc),
		.ir(ir)
	);

endmodule
