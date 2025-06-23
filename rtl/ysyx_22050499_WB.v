`include "macros.vh"
module ysyx_22050499_WB (
    input               clock,
    input               reset,
    output     [31 :0]  wb_pc,
    output     [ 4 :0]  wb_Rd,
    output     [31 :0]  reg_write_data,
    output     [31 :0]  csrs_wdata,
    input               wb_out_ready,    //下一阶段的准备信号
    input               wb_in_valid,     //上一阶段数据有效信号
    output reg          wb_in_ready,     //当前阶段是否空闲信号
    output reg          wb_out_valid,    //当前阶段输出数据有效信号
    input      [178:0]  wb_in_bits,      //上一阶段的数据
    output reg [9  :0]  wb_out_bits      //当前阶段输出数据
);

  //reg [178:0] wb_in_bits_valid;
  wire [31:0] mem_DataOut = wb_in_bits[178:147];
  wire [31:0] alu_result  = wb_in_bits[114:83];
  wire [31:0] csrs_out    = wb_in_bits[43:12];
  wire [ 1:0] MemtoReg    = wb_in_bits[11:10];
  wire [ 4:0] Rd          = wb_in_bits[ 6:2];

  assign wb_Rd = Rd;
  //选择写入GPRs的数据
  assign reg_write_data = (MemtoReg == 2'b01 ? mem_DataOut :
                          (MemtoReg == 2'b10 ? csrs_out    :
                                               alu_result));
  // 选择写入CSRs的数据
  assign csrs_wdata = alu_result;


  //=====================================================================================
  // 流水级间通信
  //=====================================================================================
  //assign wb_out_bits =  wb_in_bits[9:0];


  assign wb_pc = wb_in_bits[146:115];
  //=====================================================================================
  // 流水级信号更新逻辑
  //=====================================================================================

  always @(posedge clock) begin
    if (reset) begin
      wb_in_ready <= 1; //初始化时为空闲状态
      wb_out_valid <= 0;
    end else begin
      wb_in_ready <= 1'b1;
      if (wb_in_valid) begin
        wb_out_valid <= 1'b1;
        wb_out_bits  <= wb_in_bits[9:0];
      end else begin
        wb_out_valid <= 1'b0;
      end
    end
  end

endmodule
