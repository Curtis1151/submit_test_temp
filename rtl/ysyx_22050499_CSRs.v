module ysyx_22050499_CSRs #(
    parameter DATA_WIDTH = 32
) (
    input                       clock,
    input                       reset,
    input      [DATA_WIDTH-1:0] wdata,
    input      [           2:0] addr,
    input      [           2:0] waddr,
    input                       wen,
    input                       Ecall,
    input      [          31:0] pc,
    //output reg [DATA_WIDTH-1:0]     rf[7:0],
    output reg [DATA_WIDTH-1:0] rdata
);

  reg [DATA_WIDTH-1:0] rf[7:0];
  // rf[0] 不是csr中的值
  assign rdata = rf[addr];  //输出rs1的值
  always @(posedge clock) begin
    if (reset) begin
      rf[3'h0] <= 0;
      rf[3'h1] <= 0;
      rf[3'h2] <= 0;
      rf[3'h3] <= 0;
      rf[3'h4] <= 32'h1800;  //m_status
      rf[3'h5] <= 32'h79737978;  //mvendorid,ysyx编号
      rf[3'h6] <= 32'd22050499;  //marchid,ysyx学号
      rf[3'h7] <= 0;
    end else begin
      if (wen) rf[waddr] <= wdata;
      if (Ecall) begin
        rf[3'b010] <= pc;  //mepc
        rf[3'b011] <= 32'b1;  //mcause
      end
      rf[3'b100] <= 32'h1800;  //mstatus
      rf[3'b000] <= 32'h0;  //mstatus
    end
  end

endmodule

