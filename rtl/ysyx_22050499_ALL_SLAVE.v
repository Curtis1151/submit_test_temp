module ysyx_22050499_ALL_SLAVE (
    input             clock,
    input             reset,
    input      [31:0] raddr,
    input      [31:0] waddr,
    input      [31:0] wdata,
    input      [ 3:0] wstrb,
    input      [ 3:0] xbar_decode,
    input             ren,
    input             wen,
    output reg [31:0] slave_rdata,
    output reg        slave_arready,
    output            slave_awready,
    output            slave_wready,
    output reg        slave_rvalid
);
  //wire        slave1_arready;
  //wire        slave1_rvalid;
  //wire [31:0] slave1_rdata;
  //wire        slave1_awready;
  //wire        slave1_wready;

  //wire        slave2_arready;
  //wire        slave2_rvalid;
  //wire [31:0] slave2_rdata;
  //wire        slave2_awready;
  //wire        slave2_wready;

  wire        slave3_arready;
  wire        slave3_rvalid;
  wire [31:0] slave3_rdata;
  wire        slave3_awready;
  wire        slave3_wready;
  // 选择下游设备,各个模块被xbar_decode所限制，如果不是译码对应的设备，其功
  // 能无效
  always @(posedge clock) begin
    if (xbar_decode == 4'b0001) begin
    //=================================
    //只读设备CLINT
    //=================================
      slave_awready <= slave3_awready;
      slave_wready  <= slave3_wready;
      slave_arready <= slave3_arready;
      slave_rvalid  <= slave3_rvalid;
      slave_rdata   <= slave3_rdata;
    end else begin
      slave_awready <= 0;
      slave_wready  <= 0;
      slave_arready <= 0;
      slave_rvalid  <= 0;
      slave_rdata   <= 0;
    end
    //if (xbar_decode == 4'h0001) begin //SRAM
    //slave_awready <= slave1_awready;
    //slave_wready  <= slave1_wready;
    //slave_arready <= slave1_arready;
    //slave_rvalid  <= slave1_rvalid;
    //slave_rdata   <= slave1_rdata;
    //end else if (xbar_decode == 4'b0010) begin //UART
    //slave_awready <= slave2_awready;
    //slave_wready  <= slave2_wready;
    //slave_arready <= slave2_arready;
    //slave_rvalid  <= slave2_rvalid;
    //slave_rdata   <= slave2_rdata;

  end
  // slave3: CLINT
  ysyx_22050499_CLINT ysyx_22050499_CLINT (
      .clock      (clock),
      .reset      (reset),
      .xbar_decode(xbar_decode),
      .arready    (slave3_arready),
      .awready    (slave3_awready),
      .wready     (slave3_wready),
      .rvalid     (slave3_rvalid),
      .raddr      (raddr),
      .ren        (ren),
      .rdata      (slave3_rdata)
  );
endmodule
