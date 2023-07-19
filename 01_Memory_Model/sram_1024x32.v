/* 
 * Designed By "Shinhyndo"
 * Line Number: 1024
 * Word bit   : 32-bit
*/

module sram_1024x32
(
    input   [9:0]   addr    ,
    input           clk     ,
    input   [31:0]  data    ,
    input           wren    ,
    
    output  [31:0]  q
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

    reg     [31:0]  sram [0:1023];
    reg     [31:0]  q_r;
    reg     [9:0]   addr_r;

    /* write */
    always @ (posedge clk) begin
        if (wren) begin
            sram <= data;
        end
        addr_r <= addr; 
    end

    /* read */
    assign q = sram[addr_r];
    
endmodule