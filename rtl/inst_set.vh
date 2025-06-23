`ifndef INST_SET_VH
`define INST_SET_VH

`include "macros.vh"

/****指令类型判断*****/
`define TYPE_I ((~op[6] && ~op[5] && (op[4]+1) && ~op[3] && ~op[2] && op[1] && op[0]) || (op[6] && op[5] && ~op[4] && ~op[3] && op[2] && op[1] && op[0]))
`define TYPE_R (~op[6] && op[5] && op[4] && ~op[3] && ~op[2] && op[1] && op[0])
`define TYPE_U (~op[6] && (op[5]+1) && op[4] && ~op[3] && op[2] && op[1] && op[0])
`define TYPE_J (op[6] && op[5] && ~op[4] && op[3] && op[2] && op[1] && op[0])
`define TYPE_B (op[6] && op[5] && ~op[4] && ~op[3] && ~op[2] && op[1] && op[0])
`define TYPE_S (~op[6] && op[5] && ~op[4] && ~op[3] && ~op[2] && op[1] && op[0])
// I-type中运算类指令
`define TYPE_IR `INSTPAT_1(7'b0010011)
// I-type中LOAD指令
`define TYPE_LOAD `INSTPAT_1(7'b0000011)
// csr相关指令+ecall,ebreak
`define TYPE_IC `INSTPAT_1(7'b1110011)



/**************无条件跳转*****************/
`define INST_JAL    `INSTPAT_1(7'b1101111)
`define INST_JALR   `INSTPAT_2(3'b000,7'b1100111)

/*************有条件跳转B-type*************/
`define INST_BEQ    `INSTPAT_2(3'b000,7'b1100011)
`define INST_BNE    `INSTPAT_2(3'b001,7'b1100011)
`define INST_BLT    `INSTPAT_2(3'b100,7'b1100011)
`define INST_BGE    `INSTPAT_2(3'b101,7'b1100011)
`define INST_BLTU   `INSTPAT_2(3'b110,7'b1100011)
`define INST_BGEU   `INSTPAT_2(3'b111,7'b1100011)

/***************load I-type****************/
`define INST_LB     `INSTPAT_2(3'b000, 7'b0000011)
`define INST_LH     `INSTPAT_2(3'b001, 7'b0000011)
`define INST_LW     `INSTPAT_2(3'b010, 7'b0000011)
`define INST_LBU    `INSTPAT_2(3'b100, 7'b0000011)
`define INST_LHU    `INSTPAT_2(3'b101, 7'b0000011)

/*********store S-type*********************/
`define INST_SB     `INSTPAT_2(3'b000,7'b0100011)
`define INST_SH     `INSTPAT_2(3'b001,7'b0100011)
`define INST_SW     `INSTPAT_2(3'b010,7'b0100011)

/**************运算imm  I-type *************/
`define INST_ADDI   `INSTPAT_2(3'b000,7'b0010011)
`define INST_SLTI   `INSTPAT_2(3'b010,7'b0010011)
`define INST_SLTUI  `INSTPAT_2(3'b011,7'b0010011)
`define INST_XORI   `INSTPAT_2(3'b100,7'b0010011)
`define INST_ORI    `INSTPAT_2(3'b110,7'b0010011)
`define INST_ANDI   `INSTPAT_2(3'b111,7'b0010011)

`define INST_SLLI   `INSTPAT_3(7'b0000000, 3'b001, 7'b0010011)
`define INST_SRLI   `INSTPAT_3(7'b0000000, 3'b101, 7'b0010011)
`define INST_SRAI   `INSTPAT_3(7'b0100000, 3'b101, 7'b0010011)

/*********************  R-type *********************/
`define INST_ADD    `INSTPAT_3(7'b0000000, 3'b000, 7'b0110011)
`define INST_SUB    `INSTPAT_3(7'b0100000, 3'b000, 7'b0110011)
`define INST_SLL    `INSTPAT_3(7'b0000000, 3'b001, 7'b0110011)
`define INST_SLT    `INSTPAT_3(7'b0000000, 3'b010, 7'b0110011)
`define INST_SLTU   `INSTPAT_3(7'b0000000, 3'b011, 7'b0110011)
`define INST_XOR    `INSTPAT_3(7'b0000000, 3'b100, 7'b0110011)
`define INST_SRL    `INSTPAT_3(7'b0000000, 3'b101, 7'b0110011)
`define INST_SRA    `INSTPAT_3(7'b0100000, 3'b101, 7'b0110011)
`define INST_OR     `INSTPAT_3(7'b0000000, 3'b110, 7'b0110011)
`define INST_AND    `INSTPAT_3(7'b0000000, 3'b111, 7'b0110011)

/******************* U-type *********************/
`define INST_LUI    `INSTPAT_1(7'b0110111)
`define INST_AUIPC  `INSTPAT_1(7'b0010111)

/*************... *************/
`define INST_EBREAK (inst == 32'h00100073)
`define INST_ECALL  (inst == 32'h00000073)
`define INST_MRET   (inst == 32'h30200073)

/*************** CSR ************/
`define INST_CSRRW  `INSTPAT_2(3'b001,7'b1110011)
`define INST_CSRRS  `INSTPAT_2(3'b010,7'b1110011)
`define INST_CSRRC  `INSTPAT_2(3'b011,7'b1110011)

/********************特殊类指令*******************/
//看作普通的I指令，走运算imm通道
`define INST_FENCE_I `INSTPAT_2(3'b001,7'b0001111)


`endif
