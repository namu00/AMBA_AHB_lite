module ahb_sram
#(
    parameter ADDRESS_WIDTH = 10        ,
    parameter DATA_WIDTH = 32           ,
    parameter DEPTH = 1024              ,
    parameter BYTES = 4                 ,

    parameter BYTE_7_0 = 32'h000f       ,
    parameter BYTE_15_8 = 32'h00f0      ,
    parameter BYTE_23_16 = 32'h0f00     ,
    parameter BYTE_31_24 = 32'hf000     
)
(   
    input   [ADDRESS_WIDTH-1:0] addr    ,
    input   [DATA_WIDTH-1:0]    data    ,
    input   [BYTES-1:0]         b_en    ,
    input                       clk     ,
    input                       wren    ,

    output  [DATA_WIDTH:0]      q
);

    /**********************************************************/
    generate
    genvar  idx;
    for (idx = 0; idx < 1024; idx = idx+1) begin: datamem
	    wire [31:0] mem_sell;
	    assign mem_sell = sram[idx];
    end
    endgenerate
    /**********************************************************/

    reg     [ADDRESS_WIDTH-1:0] addr_r;
    reg     [DATA_WIDTH-1:0]    q_r;
    reg     [DATA_WIDTH-1:0]    sram [0:1023];

    /* write */
    always @ (posedge clk) begin
        if (wren) begin
            casex(b_en)
                4'bxxx1 : sram[addr] <= (BYTE_7_0 & data) | (~BYTE_7_0 & sram[addr]);
                4'bxx10 : sram[addr] <= (BYTE_15_8 & data) | (~BYTE_15_8 & sram[addr]);
                4'bx100 : sram[addr] <= (BYTE_23_16 & data) | (~BYTE_23_16 & sram[addr]);
                4'b1000 : sram[addr] <= (BYTE_31_24 & data) | (~BYTE_31_24 & sram[addr]);
                default : sram[addr] <= 32'dx;
            endcase
        end
        addr_r <= addr; 
    end

    /* read */
    assign q = sram[addr_r];
    
endmodule