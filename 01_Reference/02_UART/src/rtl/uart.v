module uart#(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input clk,
    input n_rst,

    output [7:0] uart_out,
    output uart_out_valid,
    output rx_ready,

    input [7:0] uart_in,
    input uart_in_valid,
    output tx_ready,

    input RxD, 
    output TxD
);

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    )u_uart_rx(
        .clk (clk),
        .n_rst (n_rst),

        .uart_out (uart_out),
        .uart_out_valid (uart_out_valid),
        .rx_ready (rx_ready),

        .serial_in (RxD)
    );

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    )u_uart_tx(
        .clk (clk),
        .n_rst (n_rst),

        .uart_in (uart_in),
        .uart_in_valid (uart_in_valid),
        .tx_ready (tx_ready),
        
        .serial_out (TxD)
    );
endmodule