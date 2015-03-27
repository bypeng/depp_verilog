module depp_top (
	input			clk,
	input			rst,
	output	[7:0]	led,
	inout	[7:0]	depp_db,
	input			depp_astb,
	input			depp_dstb,
	input			depp_write,
	output			depp_wait
);

	wire clkSlow, clkFast;

	wire mem_we;
	wire [7:0] mem_adr;
	wire [7:0] mem_idata;
	wire [7:0] mem_odata;
	reg [7:0] mem_data [255:0];

	assign led = 8'b0;
	
	// TODO: Generate a slow clock with 8MHz, and a fast clock in your own design
	clkgen clkgen0 ( .clk_in(clk), .clk_slow(clkSlow), .clk_fast(clkFast) );

	depp_control depp_control0 (
		.clk(clkSlow),
		.rst(rst),
		.depp_db(depp_db),
		.depp_astb(depp_astb),
		.depp_dstb(depp_dstb),
		.depp_write(depp_write),
		.depp_wait(depp_wait),
		.depp_mem_we(mem_we),
		.depp_mem_adr(mem_adr),
		.depp_mem_idata(mem_idata),
		.depp_mem_odata(mem_odata)
	) ;

	//----------------------------------------------------------------------
	// Data registers Control
	//----------------------------------------------------------------------

	integer i1;
	always @(posedge clkFast or negedge rst) begin
		if(!rst) begin
			for(i1 = 0; i1 < 128; i1 = i1 + 1)
				mem_data[i1] <= 8'h00;
		end else begin
			if(mem_we) begin
				// TODO: Define your input register constraint here
				if(mem_adr[7] == 0) begin		// Input Registers only
					mem_data[{1'b0, mem_adr[6:0]}] <= mem_idata;
				end
			end
		end
	end

	assign mem_odata = mem_data[mem_adr];

	//----------------------------------------------------------------------
	// TODO: Put your design here
	//----------------------------------------------------------------------

	// Reference Design: Not Gate
	integer i2;
	always @ (posedge clkFast) begin
		for(i2 = 0; i2 <= 127; i2 = i2 + 1)
			mem_data[i2 + 128] = ~mem_data[i2];
	end

endmodule

