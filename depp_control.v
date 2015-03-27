module depp_control (
	input			clk,
	input			rst,
	inout	[7:0]	depp_db,
	input			depp_astb,
	input			depp_dstb,
	input			depp_write,
	output			depp_wait,
	output			depp_mem_we,
	output	[7:0]	depp_mem_adr,
	output	[7:0]	depp_mem_idata,
	input	[7:0]	depp_mem_odata
) ;

	//----------------------------------------------------------------------
	//  Constant Declarations
	//----------------------------------------------------------------------
	// The following constants define state codes for the EPP port interface
	// state machine. The high order bits of the state number give a unique
	// state identifier. The low order bits are the state machine outputs for
	// that state. This type of state machine implementation uses no
	// combination logic to generate outputs which should produce glitch
	// free outputs.

	parameter st_depp_Ready =	{ 4'b0000, 5'b00000 };
	parameter st_depp_AwrA =	{ 4'b1000, 5'b00100 };
	parameter st_depp_AwrB =	{ 4'b1001, 5'b00001 };
	parameter st_depp_ArdA =	{ 4'b1010, 5'b00010 };
	parameter st_depp_ArdB =	{ 4'b1011, 5'b00011 };
	parameter st_depp_DwrA =	{ 4'b1100, 5'b01000 };
	parameter st_depp_DwrB =	{ 4'b1101, 5'b10001 };
	parameter st_depp_DrdA =	{ 4'b1110, 5'b00010 };
	parameter st_depp_DrdB =	{ 4'b1111, 5'b00011 };

	wire		clk;
	wire		rst;
	wire [7:0]	led;
	wire [7:0]	depp_db;
	wire		depp_astb;
	wire		depp_dstb;
	wire		depp_write;
	wire		depp_wait;

	//----------------------------------------------------------------------
	// Signal Declarations
	//----------------------------------------------------------------------
	// State machine current state register
	reg [8:0] st_depp_Cur = st_depp_Ready;
	reg [8:0] st_depp_Next;

	wire clkMain;					// Internal control signals
	wire ctlEppWait;
	wire ctlEppAstb;
	wire ctlEppDstb;
	wire ctlEppDir;
	wire ctlEppWr;
	wire ctlEppAwr;
	wire ctlEppDwr;
	wire [7:0] busEppOut;
	wire [7:0] busEppIn;
	reg [7:0] busEppData;			// Actually wire, used in always@(*) block
	reg [7:0] regEppAdr;			// Address Register
	reg [7:0] InRegData;			// Input Data Registers
	reg [7:0] OutRegData;			// Output Data Registers

	//----------------------------------------------------------------------
	// Module Implementation
	//----------------------------------------------------------------------

	//----------------------------------------------------------------------
	// Map basic status and control signals
	//----------------------------------------------------------------------
	assign clkMain = clk;

	assign ctlEppAstb = depp_astb;
	assign ctlEppDstb = depp_dstb;
	assign ctlEppWr = depp_write;
	assign depp_wait = ctlEppWait;

	assign busEppIn = depp_db;
	assign depp_db = ctlEppWr == 1'b1 && ctlEppDir == 1'b1 ? busEppOut : 8'bZZZZZZZZ;

	assign busEppOut = ctlEppAstb == 1'b0 ? regEppAdr : OutRegData;

	//----------------------------------------------------------------------
	// EPP Interface Control State Machine
	//----------------------------------------------------------------------
	// Map control signals from the current state
	assign ctlEppWait = st_depp_Cur[0];
	assign ctlEppDir = st_depp_Cur[1];
	assign ctlEppAwr = st_depp_Cur[2];
	assign ctlEppDwr = st_depp_Cur[3];
	assign depp_mem_we = st_depp_Cur[4];

	// This process moves the state machine to the next state
	// on each clock cycle
	always @(posedge clkMain or negedge rst) begin
		if(!rst)
			st_depp_Cur <= st_depp_Ready;
		else
			st_depp_Cur <= st_depp_Next;
	end

	// This process determines the next state machine state based
	// on the current state and the state machine inputs.
	always @(*) begin
		case(st_depp_Cur)
			// Idle state waiting for the beginning of an EPP cycle
			st_depp_Ready : begin
				if(ctlEppAstb == 1'b0) begin
					// Address read or write cycle
					if(ctlEppWr == 1'b0) begin
						st_depp_Next <= st_depp_AwrA;
					end else begin
						st_depp_Next <= st_depp_ArdA;
					end
				end else if(ctlEppDstb == 1'b0) begin
					// Data read or write cycle
					if(ctlEppWr == 1'b0) begin
						st_depp_Next <= st_depp_DwrA;
					end else begin
						st_depp_Next <= st_depp_DrdA;
					end
				end else begin
					// Remain in ready state
					st_depp_Next <= st_depp_Ready;
				end
			end
			// Write address register
			st_depp_AwrA : begin
				st_depp_Next <= st_depp_AwrB;
			end
			st_depp_AwrB : begin
				if(ctlEppAstb == 1'b0) begin
					st_depp_Next <= st_depp_AwrB;
				end else begin
					st_depp_Next <= st_depp_Ready;
				end
			end
			// Read address register
			st_depp_ArdA : begin
				st_depp_Next <= st_depp_ArdB;
			end
			st_depp_ArdB : begin
				if(ctlEppAstb == 1'b0) begin
					st_depp_Next <= st_depp_ArdB;
				end else begin
					st_depp_Next <= st_depp_Ready;
				end
			end
			// Write data register
			st_depp_DwrA : begin
				st_depp_Next <= st_depp_DwrB;
			end
			st_depp_DwrB : begin
				if(ctlEppDstb == 1'b0) begin
					st_depp_Next <= st_depp_DwrB;
				end else begin
					st_depp_Next <= st_depp_Ready;
				end
			end
			// Read data register
			st_depp_DrdA : begin
				st_depp_Next <= st_depp_DrdB;
			end
			st_depp_DrdB : begin
				if(ctlEppDstb == 1'b0) begin
					st_depp_Next <= st_depp_DrdB;
				end else begin
					st_depp_Next <= st_depp_Ready;
				end
			end
			// Some unknown state				
			default : begin
				st_depp_Next <= st_depp_Ready;
			end
		endcase
	end

	//----------------------------------------------------------------------
	// EPP Address register
	//----------------------------------------------------------------------
	assign depp_mem_adr = regEppAdr;
	always @(posedge clkMain or negedge rst) begin
		if(!rst) begin
			regEppAdr <= 8'h00;
		end else begin
			if(ctlEppAwr == 1'b1) begin
				regEppAdr <= busEppIn;
			end
		end
	end

	//----------------------------------------------------------------------
	// EPP Input Data registers
	//----------------------------------------------------------------------
	assign depp_mem_idata = InRegData;
	always @(posedge clkMain or negedge rst) begin
		if(!rst) begin
			InRegData <= 8'b00000000;
		end else begin
			if(ctlEppDwr == 1'b1) begin
				InRegData <= busEppIn;
			end
		end
	end

	//----------------------------------------------------------------------
	// EPP Output Data registers: connected to the outputs of your design
	//----------------------------------------------------------------------
	always @(posedge clkMain or negedge rst) begin
		if(!rst) begin
			OutRegData <= 8'hff;
		end else begin
			OutRegData <= depp_mem_odata;
		end
	end

endmodule

