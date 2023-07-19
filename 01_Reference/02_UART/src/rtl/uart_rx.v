module uart_rx#(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input clk,
    input n_rst,

    output [7:0] uart_out,
    output uart_out_valid,
    output rx_ready,

    input serial_in
);

    localparam TIME_EDGE = CLK_FREQ / BAUD_RATE;
    localparam CNT_WIDTH = $clog2(TIME_EDGE);
    localparam READ_TIME = TIME_EDGE / 2;

    reg busy;
    reg [CNT_WIDTH-1:0] clk_cnt;
    reg [3:0] buff_cnt;
    reg [9:0] buffer;

    wire symbol_edge;
    wire cnt_reset;
    wire start;
    wire read;
    wire eob;

    assign start = (!serial_in) && (!busy);

    assign symbol_edge = (clk_cnt == (TIME_EDGE-1)) ? 1'b1 : 1'b0;
    assign cnt_reset = (!busy) || (start) || (symbol_edge);
    assign read = (clk_cnt == READ_TIME) ? 1'b1 : 1'b0;
    assign eob = (buff_cnt == 4'hA) ? 1'b1 : 1'b0;

    assign uart_out = buffer[8:1];
    assign uart_out_valid = eob;
    assign rx_ready = !busy;

    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)
            busy <= 1'b0;
        else if(start)
            busy <= 1'b1;
        else if(eob)
            busy <= 1'b0;
        else
            busy <= busy;
    end

    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)
            clk_cnt <= 0;
        else if(cnt_reset)
            clk_cnt <= 0;
        else
            clk_cnt <= clk_cnt + 1;
    end

    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)
            buffer <= 10'h3FF;
        else if(start)
            buffer <= 10'h3FF;
        else if(read)
            buffer <= {serial_in,buffer[9:1]};
        else
            buffer <=  buffer;
    end

    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)
            buff_cnt <= 4'h0;
        else if(!busy)
            buff_cnt <= 4'h0;
        else if(symbol_edge)
            buff_cnt <= buff_cnt + 4'h1;
        else
            buff_cnt <= buff_cnt;
    end
endmodule