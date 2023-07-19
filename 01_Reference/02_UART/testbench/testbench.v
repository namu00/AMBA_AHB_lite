module testbench();
    localparam CLK_FREQ = 50_000_000;
    localparam CLK_PERIOD = 20;
    localparam BAUD_RATE = 115_200;
    localparam BAUD_TIME = 1_000_000_000 / BAUD_RATE;

    reg clk;
    reg n_rst;

    wire [7:0] uart_out;
    wire uart_out_valid;
    wire rx_ready;

    reg [7:0] uart_in;
    reg uart_in_valid;
    wire tx_ready;

    wire serial_out;

    uart uut_uart(
        .clk (clk),
        .n_rst (n_rst),

        .uart_in (uart_in),
        .uart_in_valid (uart_in_valid),
        .rx_ready (rx_ready),

        .uart_out (uart_out),
        .uart_out_valid (uart_out_valid),
        .tx_ready (tx_ready),

        .RxD(serial_out),
        .TxD(serial_out)
    );

    //uart task
    task echoback_task;
        input [7:0] data;
    begin
        $display("FPGA TRANSMIT: %x", data);
        
        uart_in_valid = 1'b1;
        uart_in = data;
        @(posedge clk);

        uart_in_valid = 1'b0;
    end
    endtask

    task check;
        input [7:0] data;
    begin
        while(!uart_out_valid)begin
            @(posedge clk);
        end    

        $display("FPGA RECEIVED: %x",uart_out);

        if(data == uart_out)
            $display("***[ PASSED ]***\n\n");
        else begin
            $display("!!![ FAILED ]!!!\n\n");
            $stop;
        end

        repeat(100) @(posedge clk);
    end
    endtask

    //clock & reset initiallize
    initial begin
        clk = 1'b0;
        n_rst = 1'b0;
        #7 n_rst = 1'b1;
    end

    //clock generation
    always #(CLK_PERIOD/2) clk = ~clk;    

    //testvector
    integer k;
    integer ans;
    initial begin
        wait(n_rst);
        @(posedge clk);

        for(k = 1; k <= 100; k = k + 1)begin
            $display("TESTCOUNT: %3d",k);
            $display("------------------");
            ans = $urandom()%8'hFF;
            fork
                echoback_task(ans);
                check(ans);
            join
        end

        $display("ALL TEST PASSED!");
        $stop;
    end
endmodule