`include "macros.vh"
`ifdef CONFIG_STA_MODE
import "DPI-C" function void get_cache_amat(input int hit,input int start_end);
`endif
module ysyx_22050499_IFU (
    input             clock,
    input             reset,
    output reg [31:0] if_pc,
    /* AXI 总线通信接口*/
    input      [31:0] rdata,
    input             if_access_done,//后期可考虑换成if_rvalid不过再说
    output     [33:0] if_axi_data,
    /* icache相关控制信号 */
    input             fence_i,
    input [127:0]     sdram_rdata,
    input             sdram_read_ok,
    output            icache_ok,

    /* 控制冒险处理接口 */
    input      [31:0] ex_dnpc,
    input             predict_wrong,
    /* 流水级通信接口 */
    input             if_out_ready, //下一阶段的准备信号
    input             if_in_valid,  //上一阶段数据有效信号
    input      [9:0]  if_in_bits,   //上一阶段的数据,初始化时默认wb阶段的输出pc为pc+4
    output reg        if_in_ready,  //当前阶段是否空闲信号
    output            if_out_valid, //当前阶段输出数据有效信号
    output     [63:0] if_out_bits,
    input      [63:0] id_in_bits
);

  //=====================================================================================
  // PC 更新逻辑
  // 1. 一切正常进行时: out_valid & out_ready 时更新PC + 4
  // 2. 预测错误时predict_wrong. 若正在取错误的PC,等待取好. 然后更新PC,不用等
  // 待下一阶段ready
  //=====================================================================================
  wire [31:0] snpc;
  assign snpc = if_pc + 32'd4;

  wire update_pc;
  assign update_pc = ( if_out_ready  & if_out_valid) ||
                     ( predict_wrong & (if_pc != ex_dnpc) & (got_inst | got_inst_t));

  always @(posedge clock) begin
    if (reset) begin
      if_pc <= 32'h3000_0000;
    end else begin
      if (update_pc) begin
        if_pc <= (predict_wrong & (if_pc != ex_dnpc)) ? ex_dnpc : snpc;
      end
    end
  end


  //=====================================================================================
  // AXI 总线通信信号
  //=====================================================================================

  wire        if_arvalid;
  wire [31:0] if_araddr;
  wire        if_rready;

  assign if_arvalid = ~(got_inst || got_inst_t);
  //assign if_araddr   = ~is_sdram ? if_pc : (if_pc&32'hFFFF_FFF0); //低4位进行归零，这个位数其实要根据icache_line_size来定
  assign if_araddr   = if_pc;
  assign if_rready   = if_access_done ? 1'b0 : 1'b1;
  assign if_axi_data = {if_araddr, if_arvalid, if_rready}; //与axi总线通信,暂时不做处理


  //=====================================================================================
  // IFU 流水级信号处理
  //=====================================================================================

  assign if_in_ready  = if_out_ready & (~predict_wrong);

  // 当发生预测错误时，保证传下去的新指令是对的
  assign if_out_valid = (got_inst_t || got_inst) && (predict_wrong ? (if_pc == ex_dnpc) :1); //默认取到的指令都有效

  assign if_out_bits  = {if_pc, ~is_sdram ? (got_inst_t ? inst : rdata) : (icache_rdata)};



  //=====================================================================================
  // 取指
  //=====================================================================================
  wire is_sdram = (if_pc >= 32'ha000_0000) && (if_pc < 32'hc000_0000);
  reg [31:0] inst;
  wire got_inst; //是否获得当前PC地址的值
  reg  got_inst_t;

  assign got_inst = if_access_done || icache_hit;

  always @(posedge clock) begin
    if (reset) begin
      got_inst_t <= 0;
    end else begin
      if (got_inst || got_inst_t) begin
        if (update_pc) begin
          got_inst_t <= 0;
        end else begin
          if (~got_inst_t) begin
            inst <= rdata;
          end else begin
            inst <= inst;
          end
          got_inst_t <= 1;
        end
      end else begin
        got_inst_t <= 0;
      end
    end
  end



  //======================================================================================
  // ICACHE
  //======================================================================================

  wire check_icache = is_sdram  && (icache_ok == 0) && (icache_hit == 0);
  wire icache_hit;
  wire [31:0] icache_rdata;


  ysyx_22050499_ICACHE icache(
    .clock             (clock            ),
    .reset             (reset            ),
    .check_icache      (check_icache     ),
    .raddr             (if_pc            ),
    .sdram_rdata       (sdram_rdata      ),
    .sdram_read_ok     (sdram_read_ok    ),
    .icache_rdata      (icache_rdata     ),
    .icache_ok         (icache_ok        ),
    .icache_hit        (icache_hit       ),
    .fence_i           (fence_i          )
  );

endmodule



