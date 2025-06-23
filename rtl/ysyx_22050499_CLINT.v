`include "macros.vh"
module ysyx_22050499_CLINT (
    input             clock,
    input             reset,
    input      [31:0] raddr,
    input      [ 3:0] xbar_decode,
    input             ren,
    output reg [31:0] rdata,
    output reg        arready,
    output            awready,
    output            wready,
    output reg        rvalid
);

  assign awready = 1'b1;  //恒为1,可以一直等待更新写addr

  reg [63:0] mtime;
  initial begin
    mtime = 0;
  end
  always @(posedge clock) begin
    if (reset) begin
      wready  <= 1'b0;
      arready <= 1'b0;
      rvalid  <= 1'b0;
      mtime   <= 64'b0;
    end else begin
      mtime <= mtime + 1;
      /* 写操作 */
      if (xbar_decode == 4'b0001) begin
        /* 读操作 */
        if (ren == 1'b1) begin  //读使能
          if (raddr == 32'h0200_0048) begin
            rdata  <= mtime[31:0];
            rvalid <= 1'b1;  // 已经读完成
          end else if (raddr == 32'h0200_004c) begin
            rdata  <= mtime[63:32];
            rvalid <= 1'b1;  // 已经读完成
          end
        end else begin
          arready <= 1'b1;
        end
      end else begin
        rvalid <= 1'b0;
      end
    end
  end

endmodule
