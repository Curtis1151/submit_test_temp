`include "macros.vh"
`ifdef CONFIG_STA_MODE
import "DPI-C" function void npc_trap();
import "DPI-C" function void isa_csrs_display();
`endif
module ysyx_22050499_EXU (
    input              clock,
    input              reset,
    output     [31:0]  ex_pc,
    input      [31:0]  mem_pc,
    output     [31:0]  ex_dnpc,

    output             predict_wrong,
    output     [4:0]  ex_Rd,

    input              ex_out_ready, //下一阶段的准备信号
    input              ex_in_valid,  //上一阶段数据有效信号
    input      [208:0] ex_in_bits,   //上一阶段的数据
    output             ex_in_ready,  //当前阶段是否空闲信号
    output             ex_out_valid, //当前阶段输出数据有效信号
    output     [148:0] ex_out_bits   //当前阶段输出数据
);

  wire [31:0] alu_result;

  wire [ 0:0] MemRe          = ex_in_bits[208:208];
  assign      ex_pc          = ex_in_bits[207:176];
  wire [ 0:0] fence_i        = ex_in_bits[175:175];
  wire [31:0] imm            = ex_in_bits[174:143];
  wire [31:0] Rs1_data       = ex_in_bits[142:111];
  wire [ 0:0] ALUASrc        = ex_in_bits[110:110];
  wire [ 2:0] ALUBSrc        = ex_in_bits[109:107];
  wire [ 0:0] SUBctr         = ex_in_bits[106:106];
  wire [13:0] OPctr          = ex_in_bits[105:92];
  wire [ 2:0] BRctr          = ex_in_bits[91:89];
  wire [ 0:0] Jump           = ex_in_bits[88:88];
  wire [ 0:0] Jump_r         = ex_in_bits[87:87];
  wire [ 0:0] Branch         = ex_in_bits[86:86];
  wire [ 0:0] Ebreak         = ex_in_bits[85:85];
  wire [ 0:0] Ecall          = ex_in_bits[84:84];
  wire [ 0:0] Mret           = ex_in_bits[83:83];
  wire [31:0] Rs2_data       = ex_in_bits[82:51];
  wire [ 2:0] MemWidth       = ex_in_bits[50:48];
  wire [ 2:0] MemDataSext    = ex_in_bits[47:45];
  wire [ 0:0] MemWe          = ex_in_bits[44:44];
  wire [31:0] csrs_out       = ex_in_bits[43:12];
  wire [ 1:0] MemtoReg       = ex_in_bits[11:10];
  wire [ 2:0] csrs_addr      = ex_in_bits[9:7];
  wire [ 4:0] Rd             = ex_in_bits[6:2];
  wire [ 0:0] CSRs_We        = ex_in_bits[1:1];
  wire [ 0:0] RegWe          = ex_in_bits[0:0];

  assign ex_Rd = Rd;




  wire [31:0] srcA;
  wire [31:0] srcB;
  /* 读取或写入数据到寄存器 */
  // 选择输入源
  assign srcA = ALUASrc ? ex_pc : Rs1_data;
  assign srcB = (ALUBSrc == 3'b000 ? Rs2_data :
                (ALUBSrc == 3'b001 ? 32'b100  :
                (ALUBSrc == 3'b010 ? imm      :
                (ALUBSrc == 3'b011 ? csrs_out :
                                      32'b0))));


  wire BR_result;
  ysyx_22050499_ALU #(32) ysyx_22050499_ALU (
      .srcA      (srcA      ),
      .srcB      (srcB      ),
      .OPctr     (OPctr     ),
      .SUBctr    (SUBctr    ),
      .BRctr     (BRctr     ),
      .BR_result (BR_result ),
      .alu_result(alu_result)
  );


  always @(posedge clock) begin
    if (Ebreak) begin
    `ifdef CONFIG_STA_MODE
      npc_trap();
    `endif
    end
    if (Ecall || Mret || CSRs_We) begin
    `ifdef CONFIG_STA_MODE
      isa_csrs_display();
    `endif
    end
  end

//=====================================================================================
// dnpc的产生逻辑
// 传递到年轻指令的年老阶段，此时dnpc必须是基于当前pc计算出来的，因此不能用
// ex_pc_t
//=====================================================================================
  assign ex_dnpc = (Jump               ? (ex_pc + imm)            :
                   (Jump_r             ? ((Rs1_data+imm)&~1)      :
                   (Branch & BR_result ? (ex_pc + imm)          :
                   (Ecall              ?  srcB                    :  //即mtvec
                   (Mret               ?  srcB + 4                :
                                         (ex_pc + 32'h4))))));



  //=====================================================================================
  // 流水级信号
  //=====================================================================================

  assign ex_out_bits  = {
    MemRe,        // bus[148:148]
    ex_pc,        // bus[147:116]
    fence_i,      // bus[115:115]
    alu_result,   // bus[114: 83]
    Rs2_data,     // bus[ 82: 51]
    MemWidth,     // bus[ 50: 48]
    MemDataSext,  // bus[ 47: 45]
    MemWe,        // bus[ 44: 44]
    csrs_out,     // bus[ 43: 12]
    MemtoReg,     // bus[ 11: 10]
    csrs_addr,    // bus[  9:  7]
    Rd,           // bus[  6:  2]
    CSRs_We,      // bus[  1:  1]
    RegWe         // bus[  0:  0]
  };

  reg ex_out_valid_t;
  assign ex_out_valid = ex_out_valid_t & (ex_pc != mem_pc);
  assign ex_in_ready  = ex_out_ready;

  assign predict_wrong = (ex_dnpc != (ex_pc + 4)); //只有接受新数据时，结果有效

  // ex_out_valid 更新逻辑
  always @(posedge clock) begin
    if (reset) begin
      ex_out_valid_t <= 0;
    end else begin
      // 获得新数据时，out_valid_t = 1
      if (ex_in_ready & ex_in_valid) begin
        ex_out_valid_t <= 1;
      // 传输数据时，out_valid_t = 0.优先级比上面的低
      end else if (ex_out_valid & ex_out_ready) begin
        ex_out_valid_t <= 0;
      end else begin
        ex_out_valid_t <= ex_out_valid_t;
      end
    end
  end


endmodule

