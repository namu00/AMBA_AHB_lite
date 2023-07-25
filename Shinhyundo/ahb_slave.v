module ahb_slave
(   
    //Address and control
    input   [31:0]  HADDR       ,
    input           HWRITE      ,       // 1 : Write, 0 : Read
    input   [2:0]   HSIZE       ,       // fixed 3'b010;
    input           HTRANS      ,       // 0 : IDLE,  1 : NONSEQ
    input           HREADY      ,
    //DATA
    input           HWDATA      ,
    //Global signals
    input           HRESETn     ,       // neg-edge reset
    input           HCLK        ,
    //Transfer response
    output          HREADYOUT   ,
    output          HRESP       ,       // only 0
    //Data
    output  [31:0]  HRDATA      
);
    wire    [31:0]  HRDATA_w;           // sram read data 
    reg     [31:0]  data_r;             // sram write data 
    reg             wren_r;             // sram write enable signal

    /* sram instantiation */
    sram_1024x32 sram_1024x32
    (
        //input
        .addr(HADDR)            ,
        .clk(HCLK)              ,
        .data(data_r)           ,
        .wren(wren_r)           ,

        //output
        .q(HRDATA_w)
    );
    
    always @ (posedge HCLK, negedge HRESETn) begin
        if(!HRESETn) begin
            wren_r <= 1'b0;
            HREADYOUT <= 1'b0;
            HRESP <= 1'b0;
        end
        else if (!HREADY) begin
            HRDATA <= 32'bx;
            HREADYOUT <= 1'b0;
            HRESP <= 1'b0;
        end
        else begin
            HRDATA <= HRDATA_w;
            HREADYOUT <= 1'b1;
            HRESP <= 1'b0;
        end
    end

endmodule