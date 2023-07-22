//==============================================
// V0.0.0 : initial ahb to sram bridge
// V0.0.1 : Debug IDLE condition & FSM logic
// V1.0.0 : Update spec to add HWORD,BYTE access (Liitle-Endian)
//==============================================

module AHB_SINGLE_PORT_SRAM_BRIDGE (
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
  
  reg [11:0]  r_haddr;
  reg [2:0]   r_hsize;
  
  //FSM state
  reg [2:0] nstate;
  reg [2:0] pstate;
  
  //wires
  wire w_ahb_trans_idle = ~|I_HTRANS;
  wire w_ahb_trans_nonseq = I_HTRANS[1]&~I_HTRANS[0];
  wire w_non_word_cond = ~(r_hsize[2]|r_hsize[1]);
  
  //capture ahb signals
  always @(posedge I_HCLK or negedge I_HRESETn) begin
    if(!I_HRESETn) r_haddr <= 12'h0;
    else if(I_HSEL & I_HREADY) r_haddr <= I_HADDR[11:0];
  end
  
  always @(posedge I_HCLK or negedge I_HRESETn) begin
    if(!I_HRESETn) r_hsize <= 3'h0;
    else if(I_HSEL & I_HREADY) r_hsize <= I_HSIZE;
  end
  
  //Hready output
  assign O_HREADYOUT = ~pstate[1];
  
  //HRESP output
  assign O_HRESP = 1'b0;
  
  //HRDATA
  always @(*) begin
    if(w_non_word_cond) begin
        if(r_size[0]) begin   //BYTE access
            case(r_haddr[1:0])
                2'b00   : O_HRDATA = {24'h00_0000,I_MRDATA[7:0]};
                2'b01   : O_HRDATA = {16'h00_0000,I_MRDATA[15:8],8'h00};
                2'b10   : O_HRDATA = {8'h00_0000,I_MRDATA[23:16],16'h0000};
                2'b11   : O_HRDATA = {I_MRDATA[31:24],24'h00_0000};
                default : O_HRDATA = {24'h00_0000,I_MRDATA[7:0]};
            endcase
        end
        else begin            //HWORD access
            case(r_haddr[1:0])
                2'b00   : O_HRDATA = {16'h0000,I_MRDATA[15:0]};
                2'b10   : O_HRDATA = {I_MRDATA[31:16],16'h0000};
                default : O_HRDATA = {16'h0000,I_MRDATA[15:0]};
            endcase
        end
    end
    else O_HRDATA = I_MRDATA; //WORD access
  end
  
  //simple control FSM
  always @(posedge I_HCLK or negedge I_HRESETn) begin
    if(!I_HRESETn)            pstate <= FSM_IDLE;
    else if(pstate != nstate) pstate <= nstate;
  end
  
  always @(*) begin
    case(pstate)
      FSM_IDLE : begin
        if(~I_HSEL)               nstate = FSM_IDLE;
        else if(w_ahb_trans_idle) nstate = FSM_IDLE;
        else if(I_HWRITE)         nstate = FSM_WRITE;
        else                      nstate = FSM_READ;
      end
      FSM_READ : begin
        if(~I_HSEL)               nstate = FSM_IDLE;
        else if(w_ahb_trans_idle) nstate = FSM_IDLE;
        else if(I_HWRITE)         nstate = FSM_WRITE;
        else                      nstate = FSM_READ;
      end
      FSM_WRITE : begin
        nstate = FSM_BUSY;
      end
      FSM_BUSY : begin
		if(~I_HSEL)               nstate = FSM_IDLE;
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
  assign O_MADDR = (I_HREADY) ? I_HADDR[11:2] : r_haddr[11:2];
  
  //WREN
  assign O_MWREN = pstate[1];
  
  //DATA
  always @(*) begin
    if(w_non_word_cond) begin
        if(r_size[0]) begin   //BYTE access
            case(r_haddr[1:0])
                2'b00   : O_MWDATA = {I_MRDATA[31:8],I_HWDATA[7:0]};
                2'b01   : O_MWDATA = {I_MRDATA[31:16],I_HWDATA[15:8],I_MRDATA[7:0]};
                2'b10   : O_MWDATA = {I_MRDATA[31:24],I_HWDATA[23:16],I_MRDATA[15:0]};
                2'b11   : O_MWDATA = {I_HWDATA[31:24],I_MRDATA[23:0]};
                default : O_MWDATA = {I_MRDATA[31:8],I_HWDATA[7:0]};
            endcase
        end
        else begin            //HWORD access
            case(r_haddr[1:0])
                2'b00   : O_MWDATA = {I_MRDATA[31:16],I_HWDATA[15:0]};
                2'b10   : O_MWDATA = {I_HWDATA[31:16],I_MRDATA[15:0]};
                default : O_MWDATA = {I_MRDATA[31:16],I_HWDATA[15:0]};
            endcase
        end
    end
    else O_MWDATA = I_HWDATA; //WORD access
  end

  
endmodule
