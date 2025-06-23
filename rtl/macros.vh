`ifndef MACROS_VH
`define MACROS_VH


/*************** 指令pattern *********************/
/*用于识别指令*/
`define INSTPAT_3(inst_funct7,inst_funct3,inst_op) ((inst_op == op)&&(inst_funct3 == funct3)&&(inst_funct7==funct7))
`define INSTPAT_2(inst_funct3,inst_op) ((inst_op == op)&&(inst_funct3 == funct3))
`define INSTPAT_1(inst_op) (inst_op == op)
/******************end**********************/

/* 用于评估时屏蔽DPI-C */
`define CONFIG_STA_MODE

`endif // MACROS_VH
