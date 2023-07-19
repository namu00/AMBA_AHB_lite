module uart_tx#(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input clk,
    input n_rst,

    input [7:0] uart_in,
    input uart_in_valid,
    output tx_ready,

    output serial_out
);

    localparam TIME_EDGE = CLK_FREQ / BAUD_RATE;
    localparam CNT_WIDTH = $clog2(TIME_EDGE);

    reg busy;
    reg [CNT_WIDTH-1:0] clk_cnt;
    reg [3:0] buff_cnt;
    reg [9:0] buffer;
    reg s_out;

    wire cnt_reset;
    wire symbol_edge;
    wire eob;


    assign symbol_edge = (clk_cnt == (TIME_EDGE-1)) ? 1'b1 : 1'b0;
    assign cnt_reset = (!busy) || (uart_in_valid) || (symbol_edge);
    assign eob = (buff_cnt == 4'hA) ? 1'b1 : 1'b0;

    assign tx_ready = !busy;
    assign serial_out = s_out;

    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)
            busy <= 1'b0;
        else if(uart_in_valid)
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
        else if(uart_in_valid)
            buffer <= {1'b1, uart_in, 1'b0};
        else if(symbol_edge)
            buffer <= {1'b1, buffer[9:1]};
        else
            buffer <= buffer;
    end

    always @(*)begin
        s_out = buffer[0];
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