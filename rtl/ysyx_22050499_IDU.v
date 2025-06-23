`include "macros.vh"
`include "inst_set.vh"

module ysyx_22050499_IDU (
    input              clock,
    input              reset,
    output     [31:0]  id_pc,
    input      [31:0]  mem_pc,

    output             raw_handle,
    input              predict_wrong,
    input [31:0]       ex_pc,
    input [31:0]       ex_dnpc,

    input              ex_in_ready,
    input              mem_in_ready,
    input              wb_in_ready, //其实是~wb_out_valid

    input      [  4:0] ex_Rd,
    input      [  4:0] mem_Rd,
    input      [  4:0] wb_Rd,

    input      [ 31:0] wb_pc,
    input              wb_RegWe,
    input              wb_CSRs_We,
    input      [  4:0] wb_reg_waddr,
    input      [  2:0] wb_csrs_waddr,
    input      [ 31:0] wb_reg_DataIn,
    input      [ 31:0] wb_csrs_wdata,

    input              id_out_ready, //下一阶段的准备信号
    input              id_in_valid,  //上一阶段数据有效信号
    input      [63 :0] id_in_bits,   //上一阶段的数据
    output             id_in_ready,  //当前阶段是否空闲信号
    output             id_out_valid, //当前阶段输出数据有效信号
    output     [208:0] id_out_bits   //当前阶段输出数据
);

  wire [31:0] inst = id_in_bits[31:0];
  assign  id_pc = id_in_bits[63:32];

  //=====================================================================================
  // ID内部控制信号生成逻辑
  //=====================================================================================
  wire        MemRe;
  wire        fence_i;
  wire [31:0] imm;
  wire [31:0] Rs1_data;
  wire [ 0:0] ALUASrc;
  wire [ 2:0] ALUBSrc;
  wire [ 0:0] SUBctr;
  wire [13:0] OPctr;
  wire [ 2:0] BRctr;
  wire [ 0:0] Jump;
  wire [ 0:0] Jump_r;
  wire [ 0:0] Branch;
  wire [ 0:0] Ebreak;
  wire [ 0:0] Ecall;
  wire [ 0:0] Mret;
  wire [31:0] Rs2_data;
  wire [ 2:0] MemWidth;
  wire [ 2:0] MemDataSext;
  wire [ 0:0] MemWe;
  wire [31:0] csrs_out;
  wire [ 1:0] MemtoReg;
  wire [ 2:0] csrs_addr;
  wire [ 4:0] Rd;
  wire [ 0:0] CSRs_We;
  wire [ 0:0] RegWe;


  assign fence_i = `INST_FENCE_I;
  wire [3:0] inst_type;
  assign inst_type =   (`INST_JAL || `INST_JALR || `TYPE_B || `INST_ECALL || `INST_MRET ? 4'h5 :
                       (`TYPE_IR  || `TYPE_R    || `TYPE_U                              ? 4'h1 :
                       (`TYPE_S                                                         ? 4'h3 :
                       (`TYPE_LOAD                                                      ? 4'h2 :
                       (`TYPE_IC                                                        ? 4'h4 :
                                                                                          4'hf)))));
  //always @(posedge clock) begin
    //if (status == 4'h1) begin
      //`ifdef CONFIG_STA_MODE
        //update_perf_counter({28'b0,inst_type});
      //`endif
      //id_valid <= 1'b1;
    //end else begin
      //id_valid <= 1'b0;
    //end
  //end


  wire [6:0] op = inst[6:0];
  wire [2:0] funct3 = inst[14:12];
  wire [6:0] funct7 = inst[31:25];
  wire [2:0] ExtOp;
  assign ExtOp =    (`TYPE_I || `TYPE_IC    ? 3'b000 :
                    (`TYPE_U                ? 3'b001 :
                    (`TYPE_S                ? 3'b010 :
                    (`TYPE_B                ? 3'b011 :
                    (`TYPE_J                ? 3'b100 :
                                              3'b111)))));

  assign RegWe = `TYPE_I || `TYPE_R || `TYPE_U || `INST_JAL || `INST_JALR || `TYPE_IC;
  assign MemWe = `TYPE_S;
  assign MemRe = `TYPE_LOAD;
  assign MemtoReg = ((op == 7'b0000011) ? 2'b01 : ((`TYPE_IC) ? 2'b10 : 2'b00));

  assign MemWidth = (`INST_SB ? 3'b001 : (`INST_SH ? 3'b010 : (`INST_SW ? 3'b100 : 3'b000)));
  assign MemDataSext =   (`INST_LB  ? 3'b001 :
                         (`INST_LBU ? 3'b010 :
                         (`INST_LH  ? 3'b011 :
                         (`INST_LHU ? 3'b100 :
                                      3'b000))));

  //包含了lui指令，但是lui不用ALU,所以不会有影响
  assign ALUASrc = `INST_JAL || `INST_JALR || `INST_AUIPC;  //为1时，选择pc


  assign ALUBSrc = ((`TYPE_R   || `TYPE_B)                  ? 3'b000 :  /* 选择rs2*/
                   ((`INST_JAL || `INST_JALR)               ? 3'b001 :  /* 选择4*/
                   ((`TYPE_I   || `TYPE_U     || `TYPE_S)   ? 3'b010 :  /* 选择imm*/
                   (`TYPE_IC   || `INST_ECALL || `INST_MRET ? 3'b011 :  /* 选择CSRs_OUT*/
                                                              3'b111))));  /* 不选择 */

  assign SUBctr = ((`TYPE_R) && (!`INST_ADD)) ||  /*不包含add的所有R指令*/
      ((op == 7'b0010011) && (funct3 != 3'b0))   || /*不包括addi的所有I运算相关指令(不包括load)*/
      (`TYPE_B);  /*用于大小比较*/


  assign BRctr =  (`INST_BEQ  ? 3'b000 :
                    (`INST_BNE  ? 3'b001 :
                    (`INST_BGE  ? 3'b010 :
                    (`INST_BGEU ? 3'b011 :
                    (`INST_BLT  ? 3'b100 :
                    (`INST_BLTU ? 3'b101 :
                                  3'b111))))));
  //加(减)法，按位或，操作数B(lui),小于置1,按位与，按位异或
  assign OPctr = (`INST_LUI                 ? 14'b0000_0000_0000_01 :  /* lui */
                 (`INST_ADD  || `INST_SUB   ? 14'b0000_0000_0000_10 :  /* 加减法 */
                 (`INST_SLL  || `INST_SLLI  ? 14'b0000_0000_0001_00 :  /* 逻辑右移 */
                 (`INST_SLT  || `INST_SLTI  ? 14'b0000_0000_0010_00 :  /* 有符号小于置1*/
                 (`INST_SLTU || `INST_SLTUI ? 14'b0000_0000_0100_00 :  /* 无符号小于置1*/
                 (`INST_XOR  || `INST_XORI  ? 14'b0000_0000_1000_00 :  /* 按位异或 */
                 (`INST_SRL  || `INST_SRLI  ? 14'b0000_0001_0000_00 :  /* 逻辑右移 */
                 (`INST_SRA  || `INST_SRAI  ? 14'b0000_0010_0000_00 :  /* 算术右移 */
                 (`INST_OR   || `INST_ORI   ? 14'b0000_0100_0000_00 :  /* 按位或 */
                 (`INST_AND  || `INST_ANDI  ? 14'b0000_1000_0000_00 :  /* 按位与 */
                 (`INST_CSRRW               ? 14'b0001_0000_0000_00 :  /* csrrw */
                 (`INST_CSRRS               ? 14'b0010_0000_0000_00 :  /* csrrs */
                 (`INST_CSRRC               ? 14'b0100_0000_0000_00 :  /* csrrc */
                                              14'b1000_0000_0000_00)))))))))))));  /* 默认就是加法 */

  assign CSRs_We = (`INST_CSRRS || `INST_CSRRW || `INST_CSRRC || `INST_ECALL);
  assign Ecall = `INST_ECALL;
  assign Mret = `INST_MRET;

  assign Jump = `INST_JAL;
  assign Jump_r = `INST_JALR;
  assign Branch = `TYPE_B;
  assign Ebreak = `INST_EBREAK;


  //=====================================================================================
  // imm扩展器
  //=====================================================================================
  ysyx_22050499_EXP ysyx_22050499_EXP (
      .inst (inst),
      .ExtOp(ExtOp),
      .imm  (imm)
  );


  //=====================================================================================
  // GPRs
  //=====================================================================================
  wire [4:0] Rs1;
  wire [4:0] Rs2;

  assign Rd  = inst[11:7];
  assign Rs1 = inst[19:15];
  assign Rs2 = inst[24:20];

  ysyx_22050499_GPRs #(16, 32) ysyx_22050499_GPRs (
      .clock   (clock),
      .reset   (reset),
      .wen     (wb_RegWe),
      .wdata   (wb_reg_DataIn),
      .waddr   (wb_reg_waddr[3:0]),  //rv32e只有16个寄存器
      .rs1     (Rs1[3:0]),
      .rs2     (Rs2[3:0]),
      .rs1_data(Rs1_data),
      .rs2_data(Rs2_data)
  );

  //=====================================================================================
  // CSRs
  //=====================================================================================
  assign csrs_addr = (Ecall ? 3'b001 : (Mret ? 3'b010 :
      /* 对应地址对应的csrs寄存器*/
      (imm == 32'h305 ? 3'b001 :  //mtvec
      (imm == 32'h341 ? 3'b010 :  //mepc
      (imm == 32'h342 ? 3'b011 :  //mcause
      (imm == 32'h300 ? 3'b100 :  //mstatus
      (imm == 32'hf11 ? 3'b101 :  //mvendorid,ysyx编号
      (imm == 32'hf12 ? 3'b110 :  //marchid, ysyx学号
      3'b000))))))));

  ysyx_22050499_CSRs #(32) ysyx_22050499_CSRs (
      .reset(reset),
      .clock(clock),
      .rdata(csrs_out),
      .Ecall(Ecall),
      .wen  (wb_CSRs_We),
      .addr (csrs_addr),
      .waddr(wb_csrs_waddr),
      //这里可能有点问题，之后再说
      .pc   (id_pc),
      //.rf   (csrs),
      .wdata(wb_csrs_wdata)
  );


  //=====================================================================================
  // ID译码结果
  //=====================================================================================
  assign id_out_bits = {
    MemRe,        //[208:208]
    id_pc,        //[207:176]
    fence_i,      //[175:175]
    imm,          // bus[174:143]
    Rs1_data,     // bus[142:111]
    ALUASrc,      // bus[110:110]
    ALUBSrc,      // bus[109:107]
    SUBctr,       // bus[106:106]
    OPctr,        // bus[105: 92]
    BRctr,        // bus[ 91: 89]
    Jump,         // bus[ 88: 88]
    Jump_r,       // bus[ 87: 87]
    Branch,       // bus[ 86: 86]
    Ebreak,       // bus[ 85: 85]
    Ecall,        // bus[ 84: 84]
    Mret,         // bus[ 83: 83]
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


  //=====================================================================================
  // *  数据冒险判断逻辑
  // ** exu,mem,wbu阶段的指令一定比id阶段年老,当其中Rd与id中rs1,rs2相同时，则
  //    可能导致数据冒险
  //=====================================================================================
  //wire [4:0] ex_Rd_valid  = ex_Rd  & {5{~ex_in_ready  & (ex_pc  != id_pc)}};
  //wire [4:0] mem_Rd_valid = mem_Rd & {5{~mem_in_ready & (mem_pc != id_pc)}};
  //wire [4:0] wb_Rd_valid  = wb_Rd  & {5{~wb_in_ready  & (wb_pc  != id_pc)}};
  wire [4:0] ex_Rd_valid  = ex_Rd  & {5{(ex_pc  != id_pc)}};
  wire [4:0] mem_Rd_valid = mem_Rd & {5{(mem_pc != id_pc)}};
  wire [4:0] wb_Rd_valid  = wb_Rd  & {5{(wb_pc  != id_pc)}};

  wire happen_raw = (id_pc != 32'h3000_0000) && ~(`INST_JAL) && ~(`TYPE_U) && ~(ex_pc == wb_pc) &&
                    (Rs1  != 0  &&                              ((Rs1 == ex_Rd_valid) || (Rs1 == mem_Rd_valid) || (Rs1 == wb_Rd_valid)) ||
                    ((Rs2 != 0) && ~(`TYPE_I) && ~(`TYPE_IC) && ((Rs2 == ex_Rd_valid) || (Rs2 == mem_Rd_valid) || (Rs2 == wb_Rd_valid)))) ;

  reg happen_raw_t; //延迟一周期的发生数据冒险判断
  assign raw_handle = happen_raw | happen_raw_t; //发生数据冒险的有效处理时间

  always @(posedge clock) begin
    if (reset) begin
    end else begin
      if (id_in_valid && id_in_ready) begin //只有准备接受新数据的时候
      end
      if (happen_raw || happen_raw_t) begin
        if (happen_raw) begin
          happen_raw_t <= 1'b1;
        end else begin
          //延迟一个周期再置0
          happen_raw_t <= 1'b0;
        end
      end
    end
  end

  //=====================================================================================
  // IDU 流水级信号处理
  //=====================================================================================
  //reg    id_in_ready_t;
  reg    id_out_valid_t;
  assign id_in_ready  = (~raw_handle) & (ex_in_ready);
  assign id_out_valid = id_out_valid_t & (id_pc != ex_pc) & (~raw_handle) & (predict_wrong ? (id_pc == ex_dnpc) :1); //输出一直有效

  //=====================================================================================
  // id_out_valid_t 更新逻辑
  //=====================================================================================
  always @(posedge clock) begin
    if (reset) begin
      id_out_valid_t <= 0;
    end else begin
      // 接受新PC时，valid_t = 1;
      if (id_in_ready & id_in_valid) begin
        id_out_valid_t <= 1;
      // 能够传输给下一阶段时,valid_t = 0;
      end else if (id_out_valid & id_out_ready) begin
        id_out_valid_t <= 0;
      end else begin
        id_out_valid_t <= id_out_valid_t;
      end
    end
  end


endmodule

