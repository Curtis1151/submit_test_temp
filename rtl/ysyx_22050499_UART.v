`include "macros.vh"
module ysyx_22050499_UART(
    input               clock,
    input               reset,
    input      [3:0]    status,
    input      [31:0]   raddr,
    input      [31:0]   waddr,
    input      [31:0]   wdata,
    input      [3:0]    wstrb,
    input      [3:0]    xbar_decode, 
    output reg          ren,
    output reg          wen,
    output reg          access_done,
    output reg [31:0]   rdata,
    output reg          arready,
    output              awready,
    output              wready,
    output reg          rvalid
);

    assign awready = 1'b1; //恒为1,可以一直等待更新写addr

    wire [4:0] shift_bits;
    assign shift_bits = (raddr[1:0] == 2'b00 ? 5'b00000 :
                        (raddr[1:0] == 2'b01 ? 5'b01000 :
                        (raddr[1:0] == 2'b10 ? 5'b10000 :
                        (raddr[1:0] == 2'b11 ? 5'b11000 :
                                               5'b00000))));

    parameter [4:0] LSFR = 5'd2;
    always @ (posedge clock) begin
        if (reset) begin
            ren       <= 1'b0;
            wen       <= 1'b0;
            wready    <= 1'b0;
            arready   <= 1'b0;
            rvalid    <= 1'b0;
        end else begin
        /* 写操作 */
            if (xbar_decode == 4'b0010) begin
                if (status == 4'h9) begin
                    if (wen==1'b1 && access_done == 1'b0) begin // 有写请求时
                        `ifdef CONFIG_STA_MODE
                        $write("%c",wdata[7:0]);
                        $fflush;//强制刷新缓冲区
                        `endif
                        access_done <= 1'b1;//写完成
                    end else begin
                        wready <= 1'b1; //使能wready,接受新信号
                    end
                /* 读操作 */
                end else if (status == 4'hC || status == 4'h0) begin
                    if (ren==1'b1 && access_done == 1'b0) begin //读使能
                        `ifdef CONFIG_STA_MODE
                        $display("错误到达UART读功能");
                        npc_assert(raddr);
                        `endif
                    end
                /* 无读写操作 */
                end else begin 
                    ren       <= 1'b0; //避免因延迟导致的错误握手
                    wen       <= 1'b0; //避免因延迟导致的错误握手
                    wready    <= 1'b0; 
                    arready   <= 1'b0;
                    rvalid    <= 1'b0;
                end
            end
        end
    end

endmodule
