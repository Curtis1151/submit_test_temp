//暂时只有加法功能
module ysyx_22050499_ALU #(DATA_WITDH = 32) (
    input [DATA_WITDH-1:0]  srcA,
    input [DATA_WITDH-1:0]  srcB,
    input                   SUBctr,
    input [13:0]            OPctr,
    input [2:0]             BRctr,
    output                  BR_result,
    output [DATA_WITDH-1:0] alu_result
);
    wire                  carry;
    wire [DATA_WITDH-1:0] and_result;
    wire [DATA_WITDH-1:0] slt_result;
    wire [DATA_WITDH-1:0] sltu_result;
    wire [DATA_WITDH-1:0] or_result;
    wire [DATA_WITDH-1:0] xor_result;
    wire [DATA_WITDH-1:0] lui_result;
    wire [DATA_WITDH-1:0] add_result;
    wire [DATA_WITDH-1:0] sll_result;
    wire [DATA_WITDH-1:0] srl_result;
    wire [DATA_WITDH-1:0] sra_result;
    wire [DATA_WITDH-1:0] csrrw_result;
    wire [DATA_WITDH-1:0] csrrc_result;
    wire [DATA_WITDH-1:0] csrrs_result;


    wire  beq_result;
    wire  bne_result;
    wire  blt_result;
    wire  bge_result;
    wire  bltu_result;
    wire  bgeu_result;

    wire op_lui     = OPctr[0];
    wire op_add_sub = OPctr[1];
    wire op_sll     = OPctr[2];
    wire op_slt     = OPctr[3];
    wire op_sltu    = OPctr[4];
    wire op_xor     = OPctr[5];
    wire op_srl     = OPctr[6];
    wire op_sra     = OPctr[7];
    wire op_or      = OPctr[8];
    wire op_and     = OPctr[9];
    wire op_csrrw   = OPctr[10];
    wire op_csrrs   = OPctr[11];
    wire op_csrrc   = OPctr[12];
    wire op_add     = OPctr[13];


    assign and_result = srcA & srcB;
    assign or_result = srcA | srcB;
    assign xor_result = srcA ^ srcB;
    assign lui_result = srcB;
    assign add_result = srcA + srcB;
    assign sll_result   = srcA << srcB[4:0];
    assign srl_result   = srcA >> srcB[4:0];
    assign sra_result   = ($signed(srcA)) >>> srcB[4:0];

    assign csrrw_result =  srcA;
    assign csrrs_result =  srcA | srcB;
    assign csrrc_result =  srcB &~ srcA;

    /*得到add,sub运算的结果*/
    wire adder_cin;    // 低位进位
    wire overflow;
    wire [DATA_WITDH-1:0] adder_A;
    wire [DATA_WITDH-1:0] adder_B;
    wire [DATA_WITDH-1:0] add_sub_result;


    assign adder_cin = SUBctr;
    assign adder_A = srcA;
    assign adder_B = srcB ^ {32{SUBctr}}; // 处理后的数据
    assign {carry,add_sub_result} = adder_A + adder_B + {31'b0,adder_cin};

    //不一定对
    assign overflow = (adder_A[31] == adder_B[31]) && (adder_A[31] != add_sub_result[31]); //溢出判断


    assign slt_result[31:1] = 31'b0;
    assign slt_result[0] = overflow ^ add_sub_result[31]; //已证明，没问题
    assign sltu_result[31:1] = 31'b0;
    assign sltu_result[0] = adder_cin ^ carry;

    /*****************分支指令************************/
    assign beq_result = srcA == srcB;
    assign bne_result = srcA != srcB;
    assign bge_result = (srcA[31] == srcB[31] ? ~add_sub_result[31] : /* 如果符号相等，则符号位为0时，符合条件*/
                        (srcA[31] == 0        ? 1                   : 0 ));  // 如果符号不相等，则当srcA为正数时，符合条件
    assign bgeu_result = carry; //add_sub运算有溢出的时候，A>=B
    assign blt_result = ~bge_result; //与bge相反
    assign bltu_result = ~bgeu_result; //与bgeu相反

    assign BR_result =  (BRctr == 3'b000 ? beq_result  :
                        (BRctr == 3'b001 ? bne_result  :
                        (BRctr == 3'b010 ? bge_result  :
                        (BRctr == 3'b011 ? bgeu_result :
                        (BRctr == 3'b100 ? blt_result  :
                        (BRctr == 3'b101 ? bltu_result :
                                           0))))));

    /***************end*******************/
    // 根据OPctr选择结果输出
    assign alu_result = ({32{op_lui     }}      & lui_result)
                      | ({32{op_add_sub }}      & add_sub_result)
                      | ({32{op_sll     }}      & sll_result)
                      | ({32{op_slt     }}      & slt_result)
                      | ({32{op_sltu    }}      & sltu_result)
                      | ({32{op_xor     }}      & xor_result)
                      | ({32{op_srl     }}      & srl_result)
                      | ({32{op_sra     }}      & sra_result)
                      | ({32{op_or      }}      & or_result)
                      | ({32{op_and     }}      & and_result)
                      | ({32{op_csrrw   }}      & csrrw_result)
                      | ({32{op_csrrs   }}      & csrrs_result)
                      | ({32{op_csrrc   }}      & csrrc_result)
                      | ({32{op_add     }}      & add_result);




endmodule
