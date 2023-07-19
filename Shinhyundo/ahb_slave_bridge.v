module ahb_slave_bridge
(   
    //Address and control
    input   [31:0]  HADDR       ,
    input           HWRITE      ,       // 1 : Write, 0 : Read
    input           HSIZE       ,
    input           HTRANS      ,       // IDLE, NONSEQ
    input           HREADY      ,
    //DATA
    input           HWDATA      ,
    //Global signals
    input           HRESETn     ,       // neg-edge reset
    input           HCLK        ,
    //Transfer response
    output          HREADYOUT   ,
    output          HRESP       ,       // Only 0
    //Data
    output  [31:0]  HRDATA      
);

    
endmodule