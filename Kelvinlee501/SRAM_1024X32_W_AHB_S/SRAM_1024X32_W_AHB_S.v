// Code your design here

module SRAM_1024X32_W_AHB_S (
  input I_HCLK,
  input I_HRESETn,
  
  input [31:0] I_HADDR,
  input [2:0]  I_HBURST,
  input        I_HMASTLOCK,
  input [3:0]  I_HPROT,
  input [2:0]  I_HSIZE,
  input [1:0]  I_HTRANS,
  input [31:0] I_HWDATA,
  input        I_HWRITE,
  
  output     [31:0] O_HRDATA,
  output            O_HREADYOUT,
  output            O_HRESP,
  
  input I_HREADY,
  input I_HSEL
);
  
  wire [9:0]  w_MADDR;
  wire [31:0] w_MWDATA;
  wire        w_MWREN;
  wire [31:0] w_q;
  
  AHB_SRAM_BRIDGE u_ahb_sram_bridge (
    .I_HCLK(I_HCLK),
    .I_HRESETn(I_HRESETn),
    .I_HADDR(I_HADDR[11:0]),
    .I_HBURST(I_HBURST),
    .I_HMASTLOCK(I_HMASTLOCK),
    .I_HPROT(I_HPROT),
    .I_HSIZE(I_HSIZE),
    .I_HTRANS(I_HTRANS),
    .I_HWDATA(I_HWDATA),
    .I_HWRITE(I_HWRITE),
    .O_HRDATA(O_HRDATA),
    .O_HREADYOUT(O_HREADYOUT),
    .O_HRESP(O_HRESP),
    .I_HREADY(I_HREADY),
    .I_HSEL(I_HSEL),
  
    .O_MADDR(w_MADDR),
    .O_MWDATA(w_MWDATA),
    .O_MWREN(w_MWREN),
    .I_MRDATA(w_q)
  );
  
  sram_1024x32 u_mem (
    .addr(w_MADDR),
    .clk(I_HCLK),
    .data(w_MWDATA),
    .wren(w_MWREN),
    .q(w_q)
  );
  
endmodule


module AHB_SRAM_BRIDGE (
  //AMBA3 AHB-lite interface
  input I_HCLK,
  input I_HRESETn,
  
  input [11:0] I_HADDR,
  input [2:0]  I_HBURST,
  input        I_HMASTLOCK,
  input [3:0]  I_HPROT,
  input [2:0]  I_HSIZE,
  input [1:0]  I_HTRANS,
  input [31:0] I_HWDATA,
  input        I_HWRITE,
  
  output     [31:0] O_HRDATA,
  output            O_HREADYOUT,
  output            O_HRESP,
  
  input I_HREADY,
  input I_HSEL,
  
  //Quatus SRAM IF
  output [9:0]  O_MADDR,
  output [31:0] O_MWDATA,
  output        O_MWREN,
  input  [31:0] I_MRDATA
);
  
  //------------------------------------
  // FSM states define
  //------------------------------------
  localparam FSM_IDLE  = 3'b000;
  localparam FSM_READ  = 3'b001;
  localparam FSM_WRITE = 3'b010;
  localparam FSM_BUSY  = 3'b100; 

  //------------------------------------
  // AHB Trans define
  //------------------------------------
  localparam TRANS_IDLE   = 2'b00;
  localparam TRANS_NONSEQ = 2'b10;
  
  reg [9:0]  r_haddr;
  
  //FSM state
  reg [2:0] nstate;
  reg [2:0] pstate;
  
  //wires
  wire w_ahb_trans_idle = ~|I_HTRANS;
  wire w_ahb_trans_nonseq = I_HTRANS[1]&I_HTRANS[0];
  
  //clock ahb address
  always @(posedge I_HCLK or negedge I_HRESETn) begin
    if(!I_HRESETn) r_haddr <= 10'h0;
    else if(I_HSEL & I_HREADY) r_haddr <= I_HADDR[11:2];
  end
  
  //Hready output
  assign O_HREADYOUT = ~pstate[1];
  
  //HRESP output
  assign O_HRESP = 1'b0;
  
  //HRDATA
  assign O_HRDATA = I_MRDATA;
  
  //simple control FSM
  always @(posedge I_HCLK or negedge I_HRESETn) begin
    if(!I_HRESETn)            pstate <= FSM_IDLE;
    else if(pstate != nstate) pstate <= nstate;
  end
  
  always @(*) begin
    case(pstate)
      FSM_IDLE : begin
        if(I_HSEL)                nstate = FSM_IDLE;
        else if(w_ahb_trans_idle) nstate = FSM_IDLE;
        else if(I_HWRITE)         nstate = FSM_WRITE;
        else                      nstate = FSM_READ;
      end
      FSM_READ : begin
        if(I_HSEL)                nstate = FSM_IDLE;
        else if(w_ahb_trans_idle) nstate = FSM_IDLE;
        else if(I_HWRITE)         nstate = FSM_WRITE;
        else                      nstate = FSM_READ;
      end
      FSM_WRITE : begin
        nstate = FSM_BUSY;
      end
      FSM_BUSY : begin
		if(I_HSEL)                nstate = FSM_IDLE;
        else if(w_ahb_trans_idle) nstate = FSM_IDLE;
        else if(I_HWRITE)         nstate = FSM_WRITE;
        else                      nstate = FSM_READ;
      end
      default : begin
        nstate = FSM_IDLE;
      end
    endcase
  end
  
  //ADDR
  assign O_MADDR = (I_HREADY) ? I_HADDR[11:2] : r_haddr;
  
  //WREN
  assign O_MWREN = pstate[1];
  
  //DATA
  assign O_MWDATA = I_HWDATA;
  
endmodule

module sram_1024x32
(
    input   [9:0]   addr    ,
    input           clk     ,
    input   [31:0]  data    ,
    input           wren    ,
    
    output  [31:0]  q
);

    reg     [31:0]  sram [0:1023];
    reg     [31:0]  q_r;
    reg     [9:0]   addr_r;
    /**********************************************************/
    generate
    	genvar  idx;
    	for (idx = 0; idx < 1024; idx = idx+1) begin: datamem
       		wire [31:0] mem_sell;
       		assign mem_sell = sram[idx];
    	end
    endgenerate
    /**********************************************************/

    
    /* write */
    always @ (posedge clk) begin
        if (wren) begin
            sram[addr_r] <= data;
        end
        addr_r <= addr; 
    end

    /* read */
    assign q = sram[addr_r];
    
endmodule
