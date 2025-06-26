`define ysyx_22050019_alu_len 33 

//`define ysyx_22050019_dpic 1

// opcode
// I type inst
`define ysyx_22050019_INST_TYPE_I 7'b0010011
`define ysyx_22050019_INST_ADDIW  7'b0011011
`define ysyx_22050019_INST_L      7'b0000011
// B type inst
`define ysyx_22050019_INST_TYPE_B 7'b1100011
// S type inst
`define ysyx_22050019_INST_TYPE_S 7'b0100011
// R type inst
`define ysyx_22050019_INST_TYPE_R 7'b0110011
`define ysyx_22050019_INST_ADDW   7'b0111011
// U type inst
`define ysyx_22050019_INST_AUIPC  7'b0010111
`define ysyx_22050019_INST_LUI    7'b0110111
// J type inst
`define ysyx_22050019_INST_JAL    7'b1101111
`define ysyx_22050019_INST_JALR   7'b1100111
// CSR type inst
`define ysyx_22050019_INST_CSR    7'b1110011

// funct3
`define ysyx_22050019_RV32_FUNCT3_000 3'b000
`define ysyx_22050019_RV32_FUNCT3_001 3'b001
`define ysyx_22050019_RV32_FUNCT3_010 3'b010
`define ysyx_22050019_RV32_FUNCT3_011 3'b011
`define ysyx_22050019_RV32_FUNCT3_100 3'b100
`define ysyx_22050019_RV32_FUNCT3_101 3'b101
`define ysyx_22050019_RV32_FUNCT3_110 3'b110
`define ysyx_22050019_RV32_FUNCT3_111 3'b111

// funct7
`define ysyx_22050019_RV32_FUNCT7_0000000  7'b0000000
`define ysyx_22050019_RV32_FUNCT7_0100000  7'b0100000
`define ysyx_22050019_RV32_FUNCT7_0000001  7'b0000001
`define ysyx_22050019_RV32_FUNCT7_0000101  7'b0000101
`define ysyx_22050019_RV32_FUNCT7_0001001  7'b0001001
`define ysyx_22050019_RV32_FUNCT7_0001101  7'b0001101
`define ysyx_22050019_RV32_FUNCT7_0010101  7'b0010101
`define ysyx_22050019_RV32_FUNCT7_0100001  7'b0100001
`define ysyx_22050019_RV32_FUNCT7_0010001  7'b0010001
`define ysyx_22050019_RV32_FUNCT7_0101101  7'b0101101
`define ysyx_22050019_RV32_FUNCT7_1111111  7'b1111111
`define ysyx_22050019_RV32_FUNCT7_0000100  7'b0000100
`define ysyx_22050019_RV32_FUNCT7_0001000  7'b0001000
`define ysyx_22050019_RV32_FUNCT7_0001100  7'b0001100
`define ysyx_22050019_RV32_FUNCT7_0101100  7'b0101100
`define ysyx_22050019_RV32_FUNCT7_0010000  7'b0010000
`define ysyx_22050019_RV32_FUNCT7_0010100  7'b0010100
`define ysyx_22050019_RV32_FUNCT7_1100000  7'b1100000
`define ysyx_22050019_RV32_FUNCT7_1110000  7'b1110000
`define ysyx_22050019_RV32_FUNCT7_1010000  7'b1010000
`define ysyx_22050019_RV32_FUNCT7_1101000  7'b1101000
`define ysyx_22050019_RV32_FUNCT7_1111000  7'b1111000
`define ysyx_22050019_RV32_FUNCT7_1010001  7'b1010001
`define ysyx_22050019_RV32_FUNCT7_1110001  7'b1110001
`define ysyx_22050019_RV32_FUNCT7_1100001  7'b1100001
`define ysyx_22050019_RV32_FUNCT7_1101001  7'b1101001

module ysyx_22050019_mux #(NR_KEY = 2, KEY_LEN = 1, DATA_LEN = 1) (
  output [DATA_LEN-1:0] out,
  input [KEY_LEN-1:0] key,
  input [DATA_LEN-1:0] default_out,
  input [NR_KEY*(KEY_LEN + DATA_LEN)-1:0] lut
);
  MuxKeyInternal #(NR_KEY, KEY_LEN, DATA_LEN, 1) i0 (out, key, default_out, lut);
endmodule
module MuxKeyInternal #(NR_KEY = 2, KEY_LEN = 1, DATA_LEN = 1, HAS_DEFAULT = 0) (
  output reg [DATA_LEN-1:0] out,
  input [KEY_LEN-1:0] key,
  input [DATA_LEN-1:0] default_out,
  input [NR_KEY*(KEY_LEN + DATA_LEN)-1:0] lut
);

  localparam PAIR_LEN = KEY_LEN + DATA_LEN;
  wire [PAIR_LEN-1:0] pair_list [NR_KEY-1:0];
  wire [KEY_LEN-1:0] key_list [NR_KEY-1:0];
  wire [DATA_LEN-1:0] data_list [NR_KEY-1:0];

  generate
    for (genvar n = 0; n < NR_KEY; n = n + 1) begin
      assign pair_list[n] = lut[PAIR_LEN*(n+1)-1 : PAIR_LEN*n];
      assign data_list[n] = pair_list[n][DATA_LEN-1:0];
      assign key_list[n]  = pair_list[n][PAIR_LEN-1:DATA_LEN];
    end
  endgenerate

  reg [DATA_LEN-1 : 0] lut_out;
  reg hit;
  integer i;
  always @(*) begin
    lut_out = 0;
    hit = 0;
    for (i = 0; i < NR_KEY; i = i + 1) begin
      lut_out = lut_out | ({DATA_LEN{key == key_list[i]}} & data_list[i]);
      hit = hit | (key == key_list[i]);
    end
    //if (!HAS_DEFAULT) out = lut_out;
    out = (hit ? lut_out : default_out);
  end
endmodule

/*
 * 一位恢复余数绝对值迭代 64/64 除法器
 *
 * 初始化：
 * 被除数寄存器为被除数的初始值，商寄存器为0，余数寄存器为0
 * 
 * 迭代计算：
 * 将余数寄存器与商寄存器相连接，被除数存在该寄存器低64位
 * 如果带符号的被除数-除数的一半，将商寄存器的最低位设为1，被除数为带符号被除数减去除数
 * 如果带符号的除被数-除数的一半，将商寄存器的最低位设为0，被除数不变
 * 
 * 结束判断：
 * 检查是否已经完成对所有商位的计算
 * 如果还没有完成，返回到步骤2进行下一次迭代
 * 如果已经完成，余数除法计算结束
 * 
 * 完成阶段：
 * 当余数除法计算结束时，商寄存器中存储的值即为最终的商，余数寄存器中存储的值即为最终的余数
 */
module ysyx_22050019_divider (
  input         clk         ,
  input         rst_n       ,
  input         div_valid   , // 除法器开始信号 
  input [7:0]   div_type_i  , // 除法类型
  input [63:0]  dividend_i  , // 被除数
  input [63:0]  divisor_i   , // 除数
  input         result_ready, // 是否准备接收
  output [63:0] div_out     , // 计算结果 
  output        div_stall   , // 计算暂停 
  output        result_ok     // 计算ok 
);
//========================================
// 除法类型判断
/*
div   : x[rd] = x[rs1] ÷𝑠 x[rs2]
divu  : x[rd] = x[rs1] ÷𝑢 x[rs2]
divuw : x[rd] = sext(x[rs1][31:0] ÷𝑢 x[rs2][31:0])
divw  : x[rd] = sext(x[rs1][31:0] ÷𝑠 x[rs2][31:0])
remu  : x[rd] = x[rs1] %𝑢 x[rs2]
rem   : x[rd] = x[rs1] %𝑠 x[rs2]
remuw : x[rd] = sext(x[rs1][31: 0] %𝑢 x[rs2][31: 0])
remw  : x[rd] = sext(x[rs1][31: 0] %𝑠 x[rs2][31: 0])
*/
localparam DIV   = 8'b10000000; // 取余数 有符号 64位 
localparam DIVU  = 8'b01000000; // 取余数 无符号 64位 
localparam DIVUW = 8'b00100000; // 取余数 无符号 32位 
localparam DIVW  = 8'b00010000; // 取余数 有符号 32位 
localparam REM   = 8'b00001000; // 除法一 有符号 64位
localparam REMU  = 8'b00000100; // 除法一 无符号 64位
localparam REMUW = 8'b00000010; // 除法一 无符号 32位
localparam REMW  = 8'b00000001; // 除法一 有符号 32位
localparam ERROR = 8'b00000000; // 遇到了除0或溢出

reg [63:0] result_exception;// 异常结果输出
reg div_zero;// 除零通知
reg div_of  ;// 溢出通知

// 32位符号拓展
wire [63:0] dividend_sext32, divisor_sext32;
assign dividend_sext32      = {{32{dividend_i[31]}}, dividend_i[31:0]};
assign divisor_sext32       = {{32{divisor_i[31]}} , divisor_i [31:0]};

// 负数处理
wire [63:0] dividend_positive, divisor_positive;
assign dividend_positive    = ~dividend_i + 1;
assign divisor_positive     = ~divisor_i + 1;

wire [63:0] dividend_positive_32, divisor_positive_32;
assign dividend_positive_32 = ~dividend_sext32 + 1;
assign divisor_positive_32  = ~divisor_sext32  + 1;

//绝对值选择
wire [63:0] dividend_abs, divisor_abs;
assign dividend_abs         = dividend_i[63] ? dividend_positive : dividend_i;
assign divisor_abs          = divisor_i[63]  ? divisor_positive  : divisor_i;

wire [63:0] dividend_abs_32, divisor_abs_32;
assign dividend_abs_32      = dividend_sext32[63] ? dividend_positive_32 : dividend_sext32;
assign divisor_abs_32       = divisor_sext32[63]  ? divisor_positive_32  : divisor_sext32;

// 除法状态机的实现
localparam IDLE    = 2'b00;
localparam DO_DIV  = 2'b01;
localparam FINISH  = 2'b10;

reg [1:0]  state, next_state;

reg [6:0]  cnt, cnt_next;
wire [63:0] result_next;
reg quotient_sign, quotient_sign_next, rem_sign, rem_sign_next;

reg [127:0] quotient, quotient_next;
reg [63:0] divisor, divisor_next;
reg [7:0]  div_type;
wire [127:0] quotient_shift; 
wire [64:0] dividend_iter;
assign dividend_iter  = quotient_shift[127:64] - divisor;
assign quotient_shift = quotient << 1;

wire [63:0] quotient_abs, rem_abs;
assign quotient_abs   = quotient_sign ? (~quotient[63:0] + 1)   : quotient[63:0];
assign rem_abs        = rem_sign      ? (~quotient[127:64] + 1) : quotient[127:64];
//========================================
// 对溢出以及除零做检测
always @(*) begin
    result_exception = 0;
    div_zero         = 0;
    div_of           = 0;
    case (div_type_i) 
      DIV: begin
        if (~|divisor_i) begin
          div_zero = 1;
          result_exception = {64{1'b1}};
        end
        else if (dividend_i == {1'b1, 63'b0} && &divisor_i) begin
          div_of = 1;
          result_exception = dividend_i;
        end
      end

      DIVU: begin
        if (~|divisor_i) begin
          div_zero = 1;
          result_exception = {64{1'b1}};
        end
      end

      DIVUW: begin
        if (~|(divisor_i[31:0])) begin
          div_zero = 1;
          result_exception = {64{1'b1}};
        end
      end

      DIVW: begin
        if (~|divisor_i) begin
          div_zero = 1;
          result_exception = {64{1'b1}};
        end
        else if (dividend_i[31:0] == {1'b1, 31'b0} && &(divisor_i[31:0])) begin
          div_of = 1;
          result_exception = dividend_sext32;
        end
      end

      REM: begin
        if (~|divisor_i) begin
          div_zero = 1;
          result_exception = dividend_i;
        end
        else if (dividend_i == {1'b1, 63'b0} && &divisor_i) begin
          div_of = 1;
          result_exception = 0;
        end
      end

      REMU: begin
        if (~|divisor_i) begin
          div_zero = 1;
          result_exception = dividend_i;
        end
      end

      REMUW: begin
        if (~|(divisor_i[31:0])) begin
          div_zero = 1;
          result_exception = dividend_sext32;
        end
      end

      REMW: begin
        if (~|(divisor_i[31:0])) begin
          div_zero = 1;
          result_exception = dividend_sext32;
        end
        else if (dividend_i[31:0] == {1'b1, 31'b0} && &(divisor_i[31:0])) begin
          div_of = 1;
          result_exception = 0;
        end
      end

      default:begin
          result_exception = 0;
          div_zero         = 0;
          div_of           = 0;
      end
    endcase
end

//========================================
// 3段式状态机构建乘法逻辑模块 
always@(posedge clk) begin
  if(rst_n)state<=IDLE;
  else    state<=next_state;
end

always @(posedge clk) begin
  if (rst_n) begin
    div_type      <= 0;
    cnt           <= 0;
    quotient_sign <= 0;
    rem_sign      <= 0;
    quotient      <= 0;
    divisor       <= 0;
  end
  else begin
    case (state)  
      IDLE : begin
        if(next_state == FINISH) begin
            div_type <= ERROR;
            quotient <= quotient_next;
        end
        else if(next_state == DO_DIV) begin
            div_type      <= div_type_i        ;
            cnt           <= cnt_next          ;
            quotient_sign <= quotient_sign_next;
            rem_sign      <= rem_sign_next     ;
            quotient      <= quotient_next     ;
            divisor       <= divisor_next      ;  
        end
        else if(next_state == IDLE) begin
            div_type      <= 0                 ;
            cnt           <= 0                 ;
            quotient_sign <= 0                 ;
            rem_sign      <= 0                 ;
            quotient      <= 0                 ;
            divisor       <= 0                 ;  
        end
      end
      DO_DIV : begin
        if(next_state == FINISH) begin
        end
        else begin
            cnt           <= cnt_next          ;
            quotient      <= quotient_next     ;
        end
      end
      FINISH : begin
        if(next_state == IDLE) begin
            div_type      <= 0                 ;
            cnt           <= 0                 ;
            quotient_sign <= 0                 ;
            rem_sign      <= 0                 ;
            quotient      <= 0                 ;
            divisor       <= 0                 ; 
        end
        else begin
        end  
      end
      default :begin
      end
    endcase
  end
end

always @(*) begin
  next_state         = state         ; 
  cnt_next           = cnt           ;
  quotient_sign_next = quotient_sign ;
  rem_sign_next      = rem_sign      ;
  quotient_next      = quotient      ;
  divisor_next       = divisor       ;
  case(state)
    IDLE: begin
      if (div_valid) begin
        if (div_zero | div_of) begin
          quotient_next[127:64] = 0;
          quotient_next[63:0] = result_exception;
          next_state          = FINISH;
        end
        else begin
          next_state = DO_DIV;
          case (div_type_i)
              DIV : begin
                cnt_next              = 64;
                quotient_sign_next    = dividend_i[63] ^ divisor_i[63];
                rem_sign_next         = dividend_i[63];
                quotient_next[127:64] = 0;
                quotient_next[63:0]   = dividend_abs;
                divisor_next          = divisor_abs;
              end

              DIVU: begin
                cnt_next              = 64;
                quotient_sign_next    = 0;
                rem_sign_next         = 0;
                quotient_next[127:64] = 0;
                quotient_next[63:0]   = dividend_i;
                divisor_next          = divisor_i;
              end

              DIVUW: begin
                cnt_next              = 32;
                quotient_sign_next    = 0;
                rem_sign_next         = 0;
                quotient_next[127:64] = 0;
                quotient_next[63:0]   = {dividend_i[31:0], 32'b0};
                divisor_next          = {32'b0, divisor_i[31:0]};
              end

              DIVW: begin
                cnt_next              = 32;
                quotient_sign_next    = dividend_i[31] ^ divisor_i[31];
                rem_sign_next         = dividend_i[31];
                quotient_next[127:64] = 0;
                quotient_next[63:0]   = {dividend_abs_32[31:0], 32'b0};
                divisor_next          = divisor_abs_32;
              end

              REM: begin
                cnt_next              = 64;
                quotient_sign_next    = dividend_i[63] ^ divisor_i[63];
                rem_sign_next         = dividend_i[63];
                quotient_next[127:64] = 0;
                quotient_next[63:0]   = dividend_abs;
                divisor_next          = divisor_abs;
              end

              REMU: begin
                cnt_next              = 64;
                quotient_sign_next    = 0;
                rem_sign_next         = 0;
                quotient_next[127:64] = 0;
                quotient_next[63:0]   = dividend_i;
                divisor_next          = divisor_i;
              end

              REMUW: begin
                cnt_next              = 32;
                quotient_sign_next    = 0;
                rem_sign_next         = 0;
                quotient_next[127:64] = 0;
                quotient_next[63:0]   = {dividend_i[31:0], 32'b0};
                divisor_next          = {32'b0, divisor_i[31:0]};
              end

              REMW: begin
                cnt_next              = 32;
                quotient_sign_next    = dividend_i[31] ^ divisor_i[31];
                rem_sign_next         = dividend_i[31];
                quotient_next[127:64] = 0;
                quotient_next[63:0]   = {dividend_abs_32[31:0], 32'b0};
                divisor_next          = divisor_abs_32;
              end

              default:begin
              end
            endcase
          end
        end
        else begin
          next_state = IDLE;
        end
      end
      DO_DIV: begin
        if (~|cnt) begin
          next_state = FINISH;
        end
        else begin
          cnt_next   = cnt - 1;
          next_state = DO_DIV;
          quotient_next[127:64] = dividend_iter[64] ? quotient_shift[127:64]       : dividend_iter[63:0];//迭代核心，相减为负，更新被除法
          quotient_next[63:0]   = dividend_iter[64] ? {quotient_shift[63:1], 1'b0} : {quotient_shift[63:1], 1'b1};
        end
      end
      FINISH: begin
        next_state = result_ready ? IDLE : FINISH;
      end
      default:begin
      end	    
      endcase
end

// 根据译码类型输出结果
ysyx_22050019_mux #( .NR_KEY(8), .KEY_LEN(8), .DATA_LEN(64)) mux_out
(
  .key         (div_type), 
  .default_out (quotient[63:0]),
  .lut         ({		
                    8'b10000000,quotient_abs,
                    8'b01000000,quotient[63:0],
                    8'b00100000,{{32{quotient[31]}},quotient[31:0]},
                    8'b00010000,{{32{quotient_abs[31]}}, quotient_abs[31:0]},
                    8'b00001000,rem_abs,
                    8'b00000100,quotient[127:64],
                    8'b00000010,{{32{quotient[95]}},quotient[95:64]},
                    8'b00000001,{{32{rem_abs[31]}}, rem_abs[31:0]}
                    }),          
  .out         (result_next)  
);

//========================================
// 输出控制
assign result_ok  = (state == FINISH);
assign div_stall  = (state == IDLE && next_state != IDLE) | (state == DO_DIV);
assign div_out    = (state == FINISH ) ? result_next : 0;

endmodule
/*
 * Radix-4 Booth 64x64 乘法器
 * 设置原因 :
 * 适配有符号数拓展为65*65，根据指令类型截取结果为输出，结果共130位数
 * 输入为64位被乘数与乘数，由于指令类型中有符号之分，因此扩展一位用于确定符号
 * 65位的被乘数再符号扩展成为130位被乘数
 * 65位的乘数，由于Booth的要求，最低位补0，最高位还需要再补符号位，结果是67位的乘数
 *
 * 计算过程 : 
 * 每次生成130位的部分积，与累加寄存器相加
 * 然后乘数右移两位，被乘数左移两位
 *
 * 结束判断 : 乘数为0，则乘法计算结束
 */


module ysyx_22050019_booth_code #(DATA_WIDTH = 64) (
    input  [DATA_WIDTH-1:0] multiplicand   , //
    input  [2:0]            code           , //
    output [DATA_WIDTH-1:0] partial_product  //
);
/*   B      操作  verilog描述
     000	  0     全0
     001	+ B     +B ={ sign,B} +0
     010	+ B     +B ={ sign,B} +0
     011	+2B     +2B={ B,0}    +0
     100	-2B     -2B={~B,1}    +1
     101	- B     -B ={~sign,~B}+1
     110	- B     -B ={~sign,~B}+1
     111	  0     全0
*/

// 被乘法数符号
wire sign = multiplicand[DATA_WIDTH-1];

// 部分积结果生成，有乘数的低3位决定
wire [DATA_WIDTH:0]op1; //符号位拓展和补1，取反等操作
wire op2;               //是否要＋1的负数补码补充

ysyx_22050019_mux #( .NR_KEY(8), .KEY_LEN(3), .DATA_LEN(DATA_WIDTH + 1)) op1_sel
(
  .key         (code), //键
  .default_out ({ (DATA_WIDTH + 1){1'b0}}),
  .lut         ({		
                 	3'b000,{ (DATA_WIDTH + 1){1'b0}},
				          3'b001,{ sign, multiplicand    },
				          3'b010,{ sign, multiplicand    },
                 	3'b011,{ multiplicand, 1'b0    },
				          3'b100,{~multiplicand, 1'b1    },
				          3'b101,{~sign, ~multiplicand   },
				          3'b110,{~sign, ~multiplicand   },
				          3'b111,{ (DATA_WIDTH + 1){1'b0}}
                    }), //键和输出的表           
  .out         (op1)  //输出
);

ysyx_22050019_mux #( .NR_KEY(8), .KEY_LEN(3), .DATA_LEN(1)) op2_sel
(
  .key         (code), //键
  .default_out (1'b0),
  .lut         ({		
                 	3'b000,1'b0,
				          3'b001,1'b0,
				          3'b010,1'b0,
                 	3'b011,1'b0,
				          3'b100,1'b1,
				          3'b101,1'b1,
				          3'b110,1'b1,
				          3'b111,1'b0
                    }), //键和输出的表           
  .out         (op2)  //输出
);
assign partial_product = op1[DATA_WIDTH-1:0] + {{(DATA_WIDTH-1){1'b0}},op2};//加法这里可以把结果扔寄存器里中继一下再加，如果这里延时太大的话可以砍一刀
endmodule
module ysyx_22050019_multiplier_cycle (
    input clk                  ,
    input rst_n                ,
    input mult_valid           , // 乘法器是否合法输入
    input [4:0] mult_type      , // 乘法类型
    input [63:0] multiplicand_i, // 被乘数
    input [63:0] multiplier_i  , // 乘数
    input        result_ready  , // 是否准备接收
    output [63:0] mult_out     , // 计算结果
    output mult_stall          , // 计算暂停 
    output result_ok             // 计算ok 
);
//========================================
// 乘法类型判断
/*
mul    : x[rd] = (x[rs1] × x[rs2])[63:0]
mulh   : x[rd] = (x[rs1]𝑠 × x[rs2]𝑠)[127:64]
mulhu  : x[rd] = (x[rs1]𝑢 × x[rs2]𝑢)[127:64]
mulhsu : x[rd] = (x[rs1]𝑠 × x[rs2]𝑢)[127:64]
mulw   : x[rd] = sext((x[rs1] × x[rs2])[31: 0])
*/
localparam MUL    = 5'b00001; // 乘
localparam MULH   = 5'b00010; // 高位乘
localparam MULHSU = 5'b00100; // 高位有符号-无符号乘
localparam MULHU  = 5'b01000; // 高位无符号乘
localparam MULW   = 5'b10000; // 乘字

// 状态机定义
localparam IDLE   = 2'b00;
localparam MULTI  = 2'b01;
localparam FINISH = 2'b10;

// 输入数根据指令类型符号拓展
// 被乘数信号声明
wire [129:0]multiplicand_trans;
reg  [129:0]multiplicand;

// 乘数信号声明
wire [64:0]multiplier_trans;
reg  [66:0]multiplier;

// 结果
reg [129:0] result;
//========================================
// 根据指令类型将输入符号拓展加入计算乘数和被乘数中
assign multiplicand_trans[129:64] = ((mult_type == MULHU) | (mult_type == MULW)) ? 66'b0 : {66{multiplicand_i[63]}};
assign multiplicand_trans[63:32]  = (mult_type == MULW) ? 32'b0 : multiplicand_i[63:32];
assign multiplicand_trans[31:0]   = multiplicand_i[31:0];

assign multiplier_trans  [64]     = ((mult_type == MULW) | (mult_type == MULHSU) | (mult_type == MULHU)) ? 1'b0 : multiplier_i[63];
assign multiplier_trans  [63:32]  = (mult_type == MULW) ? 32'b0 : multiplier_i[63:32];
assign multiplier_trans  [31:0]   = multiplier_i[31:0];

// 乘数进一步拓展，根据booth算法，乘数需要偶数，故拓展一个符号位，低位隐式补0
wire [66:0] multiplier_sext;
assign multiplier_sext            = {multiplier_trans[64], multiplier_trans[64:0], 1'b0};

//========================================
// 状态机进行部分积求和处理
reg [1:0] state, next_state;
reg [4:0] mul_type;
wire [129:0] partial_product;
ysyx_22050019_booth_code #(130)booth_code(
    .multiplicand     ( multiplicand     ),
    .code             ( multiplier[2:0]  ),
    .partial_product  ( partial_product  )
);
reg mul_h;
// 3段式状态机构建乘法逻辑模块 
always@(posedge clk) begin
  if(rst_n)state<=IDLE;
  else   state<=next_state;
end

always @(*) begin
        case(state)
          IDLE  : if(mult_valid) next_state = MULTI ;
                  else           next_state = IDLE  ;
          MULTI : if(~|multiplier) begin
                      next_state = FINISH ;
                  end
                  else next_state = MULTI  ;
          FINISH: if(result_ready)next_state = IDLE ;
                  else next_state = FINISH ;
        default : next_state=IDLE ;
        endcase
end

always @(posedge clk) begin
    if(rst_n) begin
        mul_type     <= 0;
        mul_h        <= 0;
        multiplicand <= 0;
        multiplier   <= 0;
        result       <= 0;
    end
    else begin
        case(state)
          IDLE : if(next_state == MULTI) begin
            mul_type     <= mult_type         ;
            mul_h        <= multiplier_i[63]  ;
            multiplicand <= multiplicand_trans;
            multiplier   <= multiplier_sext   ;
            result       <= 0                 ;
            end
            else begin
            mul_type     <= 0                 ;
            mul_h        <= 0                 ;
            multiplicand <= 0                 ;
            multiplier   <= 0                 ;
            result       <= 0                 ;   
            end
          MULTI: if(next_state == FINISH) begin
            result       <= result            ;
            end
            else begin
            multiplicand <= multiplicand << 2 ;
            multiplier   <= multiplier   >> 2 ;
            result       <= result + partial_product;
            end
          FINISH:if(next_state == IDLE) begin
            mul_type     <= 0                 ;
            mul_h        <= 0                 ;
            multiplicand <= 0                 ;
            multiplier   <= 0                 ;
            result       <= 0                 ; 
            end
            else begin
            mul_type     <= mul_type          ;
            multiplicand <= multiplicand      ;
            multiplier   <= multiplier        ;
            result       <= result            ;   
            end
            default :begin
            end
        endcase
    end
    
end

wire [63:0]last_multiplicand = {{2{multiplicand[125]}},multiplicand[127:66]};
wire [63:0]mulh_result =  mul_h ? result[127:64] - last_multiplicand : result[127:64];
ysyx_22050019_mux #( .NR_KEY(5), .KEY_LEN(5), .DATA_LEN(64)) ysyx_22050019_mux
(
  .key         (mul_type), //键
  .default_out (64'b0),
  .lut         ({		
                 	5'b00001,result[63:0],
				          5'b00010,mulh_result,
				          5'b00100,result[127:64],
				          5'b01000,result[127:64],
				          5'b10000,{{32{result[31]}}, result[31:0]}
                    }), //键和输出的表           
  .out         (mult_out)  //输出
);

//========================================
// 输出控制
assign result_ok  = (state == FINISH);
assign mult_stall = (state == IDLE && next_state == MULTI) | (state == MULTI);

endmodule



module ysyx_22050019_alu(
 input        clk,
 input        rst_n,
 input [63:0] op_1,
 input [63:0] op_2,
 input [`ysyx_22050019_alu_len:0] alu_sel,
 input        lsu_stall,

 output       alu_stall,
 output       alu_ok   ,
 output[63:0] result
);

wire  op_sub      = alu_sel [2] ;
wire  op_subw_32  = alu_sel [3] ;
wire  op_slt      = alu_sel [4] ;
wire  op_sltu     = alu_sel [5] ;

wire  op_sll_64   = alu_sel [9] ;
wire  op_slli_64  = alu_sel [10];
wire  op_srli_64  = alu_sel [14];
wire  op_srai_64  = alu_sel [18];

wire  op_srli_32  = alu_sel [15];
wire  op_srl_32   = alu_sel [16];



wire  op_srai_32  = alu_sel [19];
wire  op_sra_32   = alu_sel [20];

/*    alu_sel 各个位的执行命令查看表
wire  op_add_64   = alu_sel [0] ;
wire  op_add_32   = alu_sel [1] ;

wire  op_and      = alu_sel [6] ;
wire  op_or       = alu_sel [7] ;
wire  op_xor      = alu_sel [8] ;


wire  op_slli_32  = alu_sel [11];
wire  op_sll_32   = alu_sel [12];

// 右移时32位需要考虑截取,有符号用符号位填充无符号用0填充
wire  op_srl_64   = alu_sel [13];

wire  op_sra_64   = alu_sel [17];

wire  op_rem_64   = alu_sel [21];
wire  op_remu_64  = alu_sel [22];
wire  op_divu_64  = alu_sel [26];
wire  op_rem_32   = alu_sel [24];

wire  op_div_64   = alu_sel [25];
wire  op_div_32   = alu_sel [28];

wire  op_mul      = alu_sel [29];
wire  op_mulh     = alu_sel [30];
wire  op_mulhsu   = alu_sel [31];
wire  op_mulh u   = alu_sel [32];
wire  op_mul_64   = alu_sel [33];
*/

// 复用加法器的控制信号处理
wire  op_suber    = {op_sltu|op_sub|op_slt|op_subw_32} ;

// 把移位输入复用的控制信号(op2)
wire  op_shamt    = {op_sll_64|op_slli_64|op_srli_64|op_srai_64} ;
wire  data_shamt  = op_shamt ? op_2[5] : 1'b0;

// 被移位的输入选择填充信号(op1)
wire [63:0]ushif_1= (op_srli_32|op_srl_32) ? {{32{1'b0}},op_1[31:0]} : op_1;
wire [63:0]sshif_1= (op_srai_32|op_sra_32) ? {{32{op_1[31]}},op_1[31:0]} : op_1;

//加减判断，add 结果有op_suber控制为加或者减
wire [63:0] op_2_in    = op_suber ?  (~op_2 + 64'b1) : op_2  ;//加减匹配位置
wire [63:0] add        = op_1 +op_2_in;

//对add的结果进行32位截断符号拓展
wire [63:0] SEXT_add_32= {{32{add[31]}},add[31:0]};

//有符号小于则置位
wire [63:0] slt        = ( ( ( op_1[63] == 1'b1 ) && ( op_2[63] == 1'b0 ) ) 
                        | ( (op_1[63] == op_2[63] ) && ( add[63] == 1'b1 ) ) ) ? 64'b1 : 64'b0 ;

//小于则置位，无符号
wire [63:0] sltu       = ( ( ( op_1[63] == 1'b0 ) && ( op_2[63] == 1'b1 ) ) 
                        | ( (op_1[63] == op_2[63] ) && ( add[63] == 1'b1 ) ) ) ? 64'b1 : 64'b0 ;

//对操作数1逻辑右移shanmt位（空位填0)
wire [63:0] srl        = ushif_1 >> {data_shamt,op_2[4:0]};

//对操作数1算术右移位shanmt位（rs1最高位填冲)
wire [63:0] sra        = $signed(sshif_1[63:0]) >>> {data_shamt,op_2[4:0]};// 有符号数64位的需要前面也带sign不然被转为无符号数 

//对操作数1进行逻辑左移（空位填0)
wire [63:0] sll        = op_1 << {data_shamt,op_2[4:0]};

//按位与
wire [63:0] and64      = op_1 & op_2 ;

//按位或
wire [63:0] or64       = op_1 | op_2 ;

//按位异或
wire [63:0] xor64      = op_1 ^ op_2 ;

//乘法器
wire mult_valid  = |alu_sel [33:29]; 
wire result_ready= ~lsu_stall;
wire [63:0]mult_out;
wire mult_stall;
wire result_ok_mul;
ysyx_22050019_multiplier_cycle multiplier_cycle(
    .clk            ( clk            ),
    .rst_n          ( rst_n          ),
    .mult_valid     ( mult_valid     ),
    .mult_type      ( alu_sel[33:29] ),
    .multiplicand_i ( op_1           ),
    .multiplier_i   ( op_2           ),
    .result_ready   ( result_ready   ),
    .mult_out       ( mult_out       ),
    .mult_stall     ( mult_stall     ),
    .result_ok      ( result_ok_mul  )
);

//除法器
wire div_valid  = |alu_sel[28:21]; 
wire [63:0]div_out;
wire div_stall;
wire result_ok_div;
ysyx_22050019_divider divider(
    .clk           ( clk            ),
    .rst_n         ( rst_n          ),
    .div_valid     ( div_valid      ),
    .div_type_i    ( alu_sel[28:21] ),
    .dividend_i    ( op_1           ),
    .divisor_i     ( op_2           ),
    .result_ready  ( result_ready   ),
    .div_out       ( div_out        ),
    .div_stall     ( div_stall      ),
    .result_ok     ( result_ok_div  )
);
//========================================
// alu的控制信号
assign alu_stall = mult_stall    | div_stall;
assign alu_ok    = result_ok_mul | result_ok_div;
// alu的控制信号译码（用宏定义方便添加）---(实际上还是例化，端口不能写表达式，后期要删掉不然dc出网表报error)
wire [63:0]result_dm = mult_out | div_out;
ysyx_22050019_mux #( .NR_KEY(`ysyx_22050019_alu_len+1-13), .KEY_LEN(`ysyx_22050019_alu_len+1-13), .DATA_LEN(64) ) mux_alu_result
(
  .key         (alu_sel[20:0]), 
  .default_out (result_dm),
  .lut         ({
                 21'b100000000000000000000,{{32{sra[31]}},sra[31:0]},
                 21'b010000000000000000000,{{32{sra[31]}},sra[31:0]},
                 21'b001000000000000000000,sra,
                 21'b000100000000000000000,sra,
                 21'b000010000000000000000,{{32{srl[31]}},srl[31:0]},
                 21'b000001000000000000000,{{32{srl[31]}},srl[31:0]},
                 21'b000000100000000000000,srl,
                 21'b000000010000000000000,srl,
                 21'b000000001000000000000,{{32{sll[31]}},sll[31:0]},
                 21'b000000000100000000000,{{32{sll[31]}},sll[31:0]},
                 21'b000000000010000000000,sll,
                 21'b000000000001000000000,sll,
                 21'b000000000000100000000,xor64,
                 21'b000000000000010000000,or64,
                 21'b000000000000001000000,and64,
                 21'b000000000000000100000,sltu,
                 21'b000000000000000010000,slt,
                 21'b000000000000000001000,SEXT_add_32,
                 21'b000000000000000000100,add,
                 21'b000000000000000000010,SEXT_add_32,
                 21'b000000000000000000001,add
                 }),           
  .out         (result)  
);
endmodule

module ysyx_22050133_axi_arbiter(//IF&MEM输入信号
    input                               clk,
    input                               rst,

    // IFU_MEM
    output                              s1_axi_aw_ready_o,       
    input                               s1_axi_aw_valid_i,
    input [32-1:0]          s1_axi_aw_addr_i,

    output                              s1_axi_w_ready_o,        
    input                               s1_axi_w_valid_i,
    input [64-1:0]          s1_axi_w_data_i,
    input [64/8-1:0]        s1_axi_w_strb_i,
    
    input                               s1_axi_b_ready_i,      
    output                              s1_axi_b_valid_o,
    output      [1:0]                   s1_axi_b_resp_o,          

    output                              s1_axi_ar_ready_o,       
    input                               s1_axi_ar_valid_i,
    input [32-1:0]          s1_axi_ar_addr_i,
    input                               s1_axi_ar_len_i,
    input       [2:0]                   s1_axi_ar_size_i,

    input                               s1_axi_r_ready_i,            
    output                              s1_axi_r_valid_o,        
    output      [1:0]                   s1_axi_r_resp_o,
    output      [64-1:0]    s1_axi_r_data_o,

    //LSU_MEM
    output                              s2_axi_aw_ready_o,       
    input                               s2_axi_aw_valid_i,
    input [32-1:0]          s2_axi_aw_addr_i,
    input                               s2_axi_rw_len_i,
    input       [2:0]                   s2_axi_aw_size_i,

    output                              s2_axi_w_ready_o,        
    input                               s2_axi_w_valid_i,
    input [64-1:0]          s2_axi_w_data_i,
    input [64/8-1:0]        s2_axi_w_strb_i,
    input                               s2_axi_w_last_i, 

    input                               s2_axi_b_ready_i,      
    output                              s2_axi_b_valid_o,
    output      [1:0]                   s2_axi_b_resp_o,          

    output                              s2_axi_ar_ready_o,       
    input                               s2_axi_ar_valid_i,
    input [32-1:0]          s2_axi_ar_addr_i,
    input       [2:0]                   s2_axi_ar_size_i,

    input                               s2_axi_r_ready_i,            
    output                              s2_axi_r_valid_o,        
    output      [1:0]                   s2_axi_r_resp_o,
    output      [64-1:0]    s2_axi_r_data_o, 

    // arbiter<>sram
    input                               axi_aw_ready_i,             
    output                              axi_aw_valid_o,
    output     [4-1:0]       axi_aw_id_o,
    output     [32-1:0]     axi_aw_addr_o,
    output     [7:0]                    axi_aw_len_o,
    output     [2:0]                    axi_aw_size_o,
    output     [1:0]                    axi_aw_burst_o,

    input                               axi_w_ready_i,              
    output                              axi_w_valid_o,
    output     [64-1:0]     axi_w_data_o,
    output     [64/8-1:0]   axi_w_strb_o,
    output                              axi_w_last_o,
    
    output                              axi_b_ready_o,          
    input                               axi_b_valid_i,
    input  [4-1:0]           axi_b_id_i,
    input  [1:0]                        axi_b_resp_i,               

    input                               axi_ar_ready_i,             
    output                              axi_ar_valid_o,
    output     [4-1:0]       axi_ar_id_o,
    output     [32-1:0]     axi_ar_addr_o,
    output     [7:0]                    axi_ar_len_o,
    output     [2:0]                    axi_ar_size_o,
    output     [1:0]                    axi_ar_burst_o,
    
    output                              axi_r_ready_o,          
    input                               axi_r_valid_i,             
    input  [4-1:0]           axi_r_id_i,
    input  [1:0]                        axi_r_resp_i,
    input  [64-1:0]         axi_r_data_i,
    input                               axi_r_last_i
);
localparam R_IDLE = 1;
localparam R_S1   = 2;
localparam R_S2   = 3;
reg r_channel;
wire w_channel = 1;

assign s2_axi_aw_ready_o= w_channel ? axi_aw_ready_i    : 0;
assign s1_axi_aw_ready_o= ~w_channel? axi_aw_ready_i    : 0;
assign axi_aw_valid_o   = w_channel ? s2_axi_aw_valid_i : s1_axi_aw_valid_i;
assign axi_aw_id_o      = 0;
assign axi_aw_addr_o    = w_channel ? s2_axi_aw_addr_i  : s1_axi_aw_addr_i;
assign axi_aw_len_o     = w_channel ? {7'b0,s2_axi_rw_len_i}   : 0;
assign axi_aw_size_o    = w_channel ? s2_axi_aw_size_i : 3'b011;
assign axi_aw_burst_o   = 2'b01;

assign s2_axi_w_ready_o = w_channel ? axi_w_ready_i     : 0;
assign s1_axi_w_ready_o = ~w_channel? axi_w_ready_i     : 0; 
assign axi_w_valid_o    = w_channel ? s2_axi_w_valid_i  : s1_axi_w_valid_i;
assign axi_w_data_o     = w_channel ? s2_axi_w_data_i   : s1_axi_w_data_i;
assign axi_w_strb_o     = w_channel ? s2_axi_w_strb_i   : s1_axi_w_strb_i;
assign axi_w_last_o     = w_channel ? s2_axi_w_last_i   : 1'b1;

assign axi_b_ready_o    = w_channel ? s2_axi_b_ready_i  : s1_axi_b_ready_i;    
assign s2_axi_b_valid_o = w_channel ? axi_b_valid_i     : 0;
assign s2_axi_b_resp_o  = w_channel ? axi_b_resp_i      : 0;
assign s1_axi_b_valid_o = ~w_channel? axi_b_valid_i     : 0;
assign s1_axi_b_resp_o  = ~w_channel? axi_b_resp_i      : 0;

assign s2_axi_ar_ready_o= r_channel ? axi_ar_ready_i    : 0;
assign s1_axi_ar_ready_o= ~r_channel? axi_ar_ready_i    : 0;

assign axi_ar_valid_o   = r_channel ? s2_axi_ar_valid_i : s1_axi_ar_valid_i;
assign axi_ar_id_o=0;
assign axi_ar_addr_o    = r_channel ? s2_axi_ar_addr_i  : s1_axi_ar_addr_i;
assign axi_ar_len_o     = r_channel ? {7'b0,s2_axi_rw_len_i}   : {7'b0,s1_axi_ar_len_i};
assign axi_ar_size_o    = r_channel ? s2_axi_ar_size_i  : s1_axi_ar_size_i;
assign axi_ar_burst_o   = 2'b01;

assign axi_r_ready_o    = r_channel ? s2_axi_r_ready_i  : s1_axi_r_ready_i;    
assign s2_axi_r_valid_o = r_channel ? axi_r_valid_i     : 0;
assign s2_axi_r_resp_o  = r_channel ? axi_r_resp_i      : 0;
assign s2_axi_r_data_o  = r_channel ? axi_r_data_i      : 0;
assign s1_axi_r_valid_o = ~r_channel? axi_r_valid_i     : 0;
assign s1_axi_r_resp_o  = ~r_channel? axi_r_resp_i      : 0;
assign s1_axi_r_data_o  = ~r_channel? axi_r_data_i      : 0;



reg[2:0] rstate;
reg[2:0] next_rstate;
 
//========================================
// 读状态机
always@(posedge clk)begin
  if(rst)rstate<=R_IDLE;
  else rstate<=next_rstate;
end

always@(*) begin
  if(rst)next_rstate=R_IDLE;
  else case(rstate)
    R_IDLE:if(s1_axi_ar_valid_i)next_rstate=R_S1;
		  else if(s2_axi_ar_valid_i)next_rstate=R_S2;
      else next_rstate=R_IDLE;
		R_S1:if(s1_axi_r_ready_i&axi_r_valid_i&(s1_axi_ar_len_i == 0))next_rstate= s2_axi_ar_valid_i ? R_S2 :R_IDLE;
	    else next_rstate=R_S1;
		R_S2:if(s2_axi_r_ready_i&axi_r_valid_i&(s2_axi_rw_len_i == 0))next_rstate=R_IDLE;
    else next_rstate=R_S2;
    default:next_rstate=R_IDLE;
  endcase
end
always@(posedge clk)begin
  if(rst)begin
        r_channel<=0;
  end
  else begin
    case(rstate)
      R_IDLE:
      if (next_rstate==R_S1)begin
      end
      else if(next_rstate==R_S2)begin
//        arbiter_wait();//多跑3个周期平衡
        r_channel<= 1;
      end
      else begin
        r_channel<=0;
      end

      R_S1:
      if(next_rstate==R_IDLE)begin
        r_channel<=0;
      end
      else if(next_rstate==R_S2)begin
        r_channel<= 1;
      end

      R_S2:
     if(next_rstate==R_IDLE)begin
        r_channel<=0;
      end

      default:begin
      end
    endcase
  end
end
endmodule
// 将axi的请求合并成为axi_full的格式
module ysyx_22050019_axi_interconnect (
    input                               clk,
    input                               rst,

    output                              axii_icache_ar_ready,             
    input                               axii_icache_ar_valid,
    input     [31:0]                    axii_icache_ar_addr,
    input                               axii_icache_ar_len,
    input     [2:0]                     axii_icache_ar_size,
    
    input                               axii_icache_r_ready,          
    output reg                          axii_icache_r_valid,             
    output reg [63:0]                   axii_icache_r_data,

    // 转换访问请求为axi_full
    input                               axii_ar_ready,             
    output reg                          axii_ar_valid,
    output reg [31:0]                   axii_ar_addr,
    output reg                          axii_ar_len,
    output reg [2:0]                    axii_ar_size,
    
    output reg                          axii_r_ready,          
    input                               axii_r_valid,             
    input  [63:0]                       axii_r_data
);
//========================================
// 读通道解析
localparam RS_IDLE = 0;
localparam RS_ARHS = 1;
localparam RS_RHS  = 2;
localparam RS_ARHS1= 3;
localparam RS_RHS1 = 4;
localparam RS_DHS  = 5;


reg r_addr_ready;
assign axii_icache_ar_ready = r_addr_ready;

reg r_data_valid;
assign axii_icache_r_valid  = r_data_valid;

reg[3:0] rstate;
reg[3:0] next_rstate;


//读通道解析

reg  [31:0]              r_addr;        
reg  [7:0]               r_len;        

always@(posedge clk)begin
  if(rst)rstate<=RS_IDLE;
  else rstate<=next_rstate;
end

always@(*) begin
  if(rst)next_rstate=RS_IDLE;
  else case(rstate)
    RS_IDLE:if(axii_icache_ar_valid&axii_icache_ar_ready)next_rstate=RS_ARHS;
      else next_rstate=RS_IDLE;

    RS_ARHS:if(axii_ar_valid&axii_ar_ready)next_rstate=RS_RHS;
    else next_rstate=RS_ARHS;

    RS_RHS:if(axii_r_ready&axii_r_valid)next_rstate=RS_ARHS1;
    else next_rstate=RS_RHS;

    RS_ARHS1:if(axii_ar_valid&axii_ar_ready)next_rstate=RS_RHS1;
    else next_rstate=RS_ARHS1;

    RS_RHS1:if(axii_r_ready&axii_r_valid)next_rstate=RS_DHS;
    else next_rstate=RS_RHS1;

    RS_DHS:if(axii_icache_r_valid&axii_icache_r_ready)
             if(r_len==0)next_rstate=RS_IDLE;
             else next_rstate=RS_ARHS;
    else next_rstate=RS_DHS;

    default:begin
      next_rstate=RS_IDLE;
    end
  endcase
end
reg [63:0] r_data_o_reg;  
assign axii_icache_r_data=r_data_o_reg;
always@(posedge clk)begin
  if(rst)begin
        r_addr         <= 0;
        r_len          <= 0;
        r_addr_ready   <= 0;
        r_data_valid   <= 0;
        r_data_o_reg   <= 0;
        axii_ar_valid  <= 0;
        axii_ar_addr   <= 0;
        axii_ar_len    <= 0;
        axii_ar_size   <= 0;
        axii_r_ready   <= 0;
  end
  else begin
    case(rstate)
      RS_IDLE:
      if(next_rstate==RS_ARHS)begin
        r_addr         <= axii_icache_ar_addr;
        r_len          <= 1;
        r_addr_ready   <= 0;
        axii_ar_valid  <= 1;
        axii_ar_addr   <= axii_icache_ar_addr;
        axii_ar_len    <= 0;
        axii_ar_size   <= 3'b010;
      end
      else begin
        r_addr_ready   <= 1;
      end

      RS_ARHS:if(next_rstate==RS_RHS)begin
        axii_ar_valid <= 0;
        axii_r_ready  <= 1;
      end

      RS_RHS:if(next_rstate==RS_ARHS1)begin
          axii_r_ready   <= 0;
          r_data_valid   <= 0;
          r_data_o_reg   <= {32'b0,axii_r_data[31:0]};

          axii_ar_valid  <= 1;
          axii_ar_addr   <= r_addr+4;
          axii_ar_len    <= 0;
          axii_ar_size   <= 3'b010;
      end

      RS_ARHS1:if(next_rstate==RS_RHS1)begin
        axii_ar_valid <= 0;
        axii_r_ready  <= 1;
      end

      RS_RHS1:if(next_rstate==RS_DHS)begin
          axii_r_ready   <= 0;
          r_data_valid   <= 1;
          r_data_o_reg   <= {axii_r_data[31:0],r_data_o_reg[31:0]};


          axii_ar_valid  <= 0;
          axii_ar_addr   <= 0;
          axii_ar_len    <= 0;
          axii_ar_size   <= 0;
      end
      
      RS_DHS:if(next_rstate==RS_ARHS)begin
          r_data_valid   <= 0;
          axii_r_ready   <= 0;
          r_addr         <= r_addr+8;
          r_len          <= r_len-1;

          axii_ar_valid  <= 1;
          axii_ar_addr   <= r_addr+8;
          axii_ar_len    <= 0;
          axii_ar_size   <= 3'b010;
      end
      else if(next_rstate==RS_IDLE)begin
          r_addr         <= 0;
          r_len          <= 0;
          r_addr_ready   <= 1;
          r_data_valid   <= 0;
          r_data_o_reg   <= 0;
          axii_ar_valid  <= 0;
          axii_ar_addr   <= 0;
          axii_ar_len    <= 0;
          axii_ar_size   <= 0;
          axii_r_ready   <= 0;
      end
      default:begin
      end
    endcase
  end
end

endmodule

module ysyx_22050019_CSR(
    input clk,
    input rst_n,
    input [63:0]pc,
    
    input [7:0]  csr_inst_type,
    input [11:0] csr_addr,
    input        csr_wen,
    input [63:0] rdata1_reg_csr,//从reg读到的数据
    input[4:0]   zimm,
    input        time_req,
    input        stall_nop,
    
    output[63:0] snpc,
    output       time_interrupt,
`ifdef ysyx_22050019_dpic
    output[63:0] csr_regs_diff [3:0],     //csr to reg for diff
`endif
    output[63:0] wdate_csr_reg//向reg写的数据

);
//csr指令信号接受---------------------
//csr信号助释---csrw[0],---mepc[1]---mcause[2]---mstatus[3]

// csr写入x[rd]，x[rs1]写入csr
wire csrrw_w  = csr_inst_type[0];
// 环境调用
wire ecall_w  = csr_inst_type[1];

// 读csr和x[rs1]按位或结果再写回csr，原本csr值写回x[rd]
/* verilator lint_off UNUSED */
wire csrrs_w  = csr_inst_type[2];
// 从中断异常处理程序返回
wire mret_w   = csr_inst_type[3];
// 读csr和x[rs1]按位与结果再写回csr，原本csr值写回x[rd]
wire csrrc_w  = csr_inst_type[4];
// csr写入x[rd]，zimm写入csr
wire csrrwi_w = csr_inst_type[5];
// csr写入x[rd]，zimm|csr和x写入csr
wire csrrsi_w = csr_inst_type[6];
// csr写入x[rd]，zimm&csr和x写入csr
wire csrrci_w = csr_inst_type[7];
reg [63:0] rdata;

//************
//csr_wdata->用mux通过通过类型控制读入数据
wire  [63:0] csr_wdata;
wire [63:0]temp_0 = rdata1_reg_csr  | rdata;
wire [63:0]temp_1 = (~rdata1_reg_csr) & rdata;
wire [63:0]temp_2 = {59'b0, zimm};
wire [63:0]temp_3 = {59'b0, zimm} | rdata;
wire [63:0]temp_4 = (~{59'b0, zimm}) | rdata;
ysyx_22050019_mux #( .NR_KEY(6), .KEY_LEN(8), .DATA_LEN(64)) mux_csr_wdata
(
  .key         (csr_inst_type), //键
  .default_out ({64{1'b0}}),
  .lut         ({
                8'b1000_0000,temp_4, 
                8'b0100_0000,temp_3, 
                8'b0010_0000,temp_2, 
                8'b0001_0000,temp_1,   
                8'b0000_0100,temp_0,
                8'b0000_0001,rdata1_reg_csr
                
                }),           
  .out         (csr_wdata)  //输出
);

/*csr寄存器的声明
csr[0] == mtvec csr[1] == mepc csr[2] == mstatus csr[3] == mcause  csr[4]= mstatus
*/
//************    
// CSR local define 
localparam CSR_MSTATUS       = 12'h300;
localparam CSR_MIE           = 12'h304;
localparam CSR_MTVEC         = 12'h305;
localparam CSR_MEPC          = 12'h341;
localparam CSR_MCAUSE        = 12'h342;
localparam CSR_MIP           = 12'h344;
localparam CSR_MHARTID       = 12'hF14;

// 计时器中断判断信号
wire mie_mtie;
wire mstatus_mie;
wire mip_mtip;

assign time_interrupt = time_req & mie_mtie & mstatus_mie &~mret_w &~ecall_w  & stall_nop;
/* =========================mtvec==================================== */
// 机器模式异常入口基地址寄存器|_|  = {base[maxlen-1:2], mode[1:0]}
reg [63:0] mtvec;
wire [61:0] mtvec_base = mtvec[63:2];
wire [1:0] mtvec_mode = mtvec[1:0];

  always @(posedge clk) begin
    if (rst_n) begin
      mtvec <= 64'b0;
    end
    else if (csrrw_w&&csr_addr == CSR_MTVEC) begin
      mtvec <= csr_wdata;
    end
  end

/* ==============================mepc============================== */
// 机器模式异常PC寄存器
reg [63:0] mepc;

always @(posedge clk) begin
  if (rst_n) begin
    mepc <= 64'b0;
  end
  else if (ecall_w || time_interrupt) begin
    mepc <= pc;
  end
  else if (csr_wen&&csr_addr == CSR_MEPC)
    mepc <= csr_wdata;
end

/* =============================mcause============================= */
// 机器模式异常原因寄存器
// mcause = {interupt[63], Exception code}
reg [63:0] mcause;

always @(posedge clk) begin
  if (rst_n) begin
    mcause <= 64'b0;
  end
  else if(time_interrupt)
    mcause <= 64'h8000000000000007;
  else if (ecall_w) begin
    mcause <= 64'd11;
    end
  else if (csr_wen&&csr_addr == CSR_MCAUSE)
    mcause <= csr_wdata;
end

/* =============================mstatus============================ */
// 跟踪控制处理器当前运行状态寄存器
/* [12-11]MPP(2)[在trap前的特权模式],[7]MPIE(1)[trap前的mie位的值],[3]MIE(1)[启动禁用全局终端]*/
reg [63:0] mstatus;
wire mstatus_mpie = mstatus[7];
assign mstatus_mie = mstatus[3];

always @(posedge clk) begin
  if (rst_n) begin
    mstatus <= 64'hA00001800;
  end
  else if(ecall_w || time_interrupt) begin
      mstatus[7] <= mstatus_mie;
      mstatus[3] <= 1'b0;
  end
`ifdef ysyx_22050019_dpic
`else
  else if(mret_w) begin
      mstatus[3] <= mstatus_mpie;
      mstatus[7] <= 1'b1;
  end
`endif

  else if (csr_wen&&csr_addr == CSR_MSTATUS)
    mstatus <= csr_wdata;
end

/* =============================mie================================= */
// 包含中断启用位寄存器
/* [7]MTIE(1)寄存器中断启用位*/
reg [63:0] mie;
assign mie_mtie = mie[7];

always @(posedge clk) begin
  if (rst_n) begin
    mie <= 64'b0;
  end
  else if(csr_wen && csr_addr == CSR_MIE)
    mie <= csr_wdata;
end

/* =============================mip================================= */
// 中断等待寄存器
/* [7]MTIP(1)寄存器中断启用位*/
reg [63:0] mip;
assign mip_mtip = mip[7];
always @(posedge clk) begin
  if (rst_n) begin
    mip <= 64'b0;
  end
  else begin
      mip[7] <= time_req;
  end
    
end

/* =============================mhartid================================= */
// 上下文切换寄存器
reg [63:0] mhartid;
always @(posedge clk) begin
  if (rst_n) begin
    mhartid <= 64'b0;
  end
  else if(csr_wen && csr_addr == CSR_MHARTID)
    mhartid <= csr_wdata;
end

//*********************** CSR Read Sel********************************

//通过csr地址选择读取哪一个csr寄存器

always @(*) begin
  rdata = 64'b0;
  case(csr_addr)
    CSR_MTVEC   : rdata = mtvec;
    CSR_MCAUSE  : rdata = mcause;
    CSR_MSTATUS : rdata=  mstatus;
    CSR_MEPC    : rdata = mepc;
    CSR_MIE     : rdata = mie;
    CSR_MIP     : rdata = mip;
    CSR_MHARTID : rdata = mhartid;
    default     : rdata = 64'b0;
  endcase
end

//csr对外输出的信号的控制和处理

assign wdate_csr_reg = rdata;
assign snpc    = ecall_w | time_interrupt ? mtvec :
                 mret_w  ? mepc  :64'b0;

// =====================

//*********************** csr_regs给diff传递部分csr信息******************
`ifdef ysyx_22050019_dpic
assign csr_regs_diff[0] =mtvec  ;
assign csr_regs_diff[1] =mepc   ;
assign csr_regs_diff[2] =mstatus;
assign csr_regs_diff[3] =mcause ;
`endif


endmodule
/*
 * icache - config_Fire
 * 只能读取
 *
 *  |     Tag     |     Index     |          Offset          |
 *  |             |               |                          |
 * 31            10|9            4|3                         0
 * 
 * 每行共2字即16字节即128位，2路组相联
 * 共128行，总大小为8KiB

 * 物理地址总长为32位
 * 每一行字长合计16字节 - Byte  4位
 * 共128行,2路组相连   - Index 6位
 * Tag = 32 - 3 - 6  = 22位
 */
module ysyx_22050019_dcache(
  input  clk                                             ,
  input  rst                                             ,

  input                              clint_addr          , 
  output                             time_req            , 
  input                              fence_i             , 
  input                              ar_valid_i          ,         
  output reg                         ar_ready_o          ,     
  input     [32-1:0]         ar_addr_i           ,             
  output                             r_data_valid_o      ,     
  input                              r_data_ready_i      ,
  input     [1:0]                    r_resp_i            ,     
  output    [64-1:0]         r_data_o            ,
  input                              aw_valid_i          ,         
  output reg                         aw_ready_o          ,      
  input     [32-1:0]         aw_addr_i           ,             
  input                              w_data_valid_i      ,     
  output reg                         w_data_ready_o      ,
  input     [64/8-1:0]       w_w_strb_i          ,     
  input     [64-1:0]         w_data_i            ,   
  input                              b_ready_i           ,      
  output reg                         b_valid_o           ,
  output reg  [1:0]                  b_resp_o            , 
  output [5:0]    io_sram2_addr     ,
  output          io_sram2_cen      ,
  output          io_sram2_wen      ,
  output [127:0]  io_sram2_wmask    ,  
  output [127:0]  io_sram2_wdata    ,  
  input  [127:0]  io_sram2_rdata    ,  
  output [5:0]    io_sram3_addr     ,
  output          io_sram3_cen      ,
  output          io_sram3_wen      ,
  output [127:0]  io_sram3_wmask    ,  
  output [127:0]  io_sram3_wdata    ,  
  input  [127:0]  io_sram3_rdata    ,  
  output reg                         fence_stall_o       ,  
  output reg                         cache_aw_valid_o    ,       
  input                              cache_aw_ready_i    ,     
  output reg[32-1:0]         cache_aw_addr_o     ,
  output reg                         cache_rw_len_o      ,           
  input                              cache_w_ready_i     ,     
  output reg                         cache_w_valid_o     ,     
  output reg[64-1:0]         cache_w_data_o      ,
  output reg[64/8-1:0]       cache_w_strb_o      ,
  output reg                         cache_w_last_o      ,  
  output reg                         cache_b_ready_o     ,          
  input                              cache_b_valid_i     ,
  input  [1:0]                       cache_b_resp_i      , 
  output reg                         cache_ar_valid_o    ,       
  input                              cache_ar_ready_i    ,     
  output reg[32-1:0]         cache_ar_addr_o     ,          
  output reg                         cache_r_ready_o     ,     
  input                              cache_r_valid_i     ,
  input     [1:0]                    cache_r_resp_i      ,      
  input     [64-1:0]         cache_r_data_i
);

localparam S_IDLE =0;
localparam S_HIT  =1;
localparam S_AR   =2;
localparam S_R    =3;
localparam S_AW   =4;
localparam S_W    =5;
localparam S_B    =6;
localparam CLINT  =7;
localparam FENCE_I=8;
wire [32-1:0]  rw_addr_i = ar_addr_i|aw_addr_i   ;

//fence
integer j;
integer k;
reg fence_stall;
reg [6+1:0]fence_cnt  ;
// 状态机信号
reg[15:0] state;
reg[15:0] next_state;
// 保存地址，miss后的写数据，偏移寄存器
reg [32-1:0]   addr  ;
wire[6-1:0]  index = addr[9:4];
reg rw_control;
// tag和标记位的寄存器值
reg [22-1:0] tag  [2-1:0][64-1:0];
reg                 valid[2-1:0][64-1:0];
reg                 dirty[2-1:0][64-1:0];
wire [64-1:0]  maskn;
// wire类型传入的地址解析
wire[22-1:0]    tag_in  = rw_addr_i[31:10]    ;
wire[6-1:0]  index_in= rw_addr_i[9:4];
wire[4-1:0] OFFSET0 = 0                       ;//3'b0对于这里是持有怀疑态度的

// 命中路的判断逻辑      0-1 两路
wire[2-1:0]hit_wayflag;
wire[1-1:0]hit_waynum_i=hit_wayflag==2'b01 ? 0
                          :hit_wayflag==2'b10 ? 1
                          :0;
reg[1-1:0]waynum;
reg[1-1:0]random;
always@(posedge clk)begin//随机替换的替换策略
  if(rst)random<=0;
  else random<=random+1;
end

// clint
reg [63:0] mtime, mtimecmp;
assign time_req    = (mtime >= mtimecmp);
wire mtime_ack =(aw_addr_i == 32'h200bff8) && state == CLINT && w_data_valid_i && w_data_ready_o;
always @(posedge clk) begin
    if(rst) begin
        mtime <= 0;
    end
    else if(mtime_ack)begin
        mtime <= (w_data_i&maskn)|(mtime&(~maskn));
    end
    else begin
        mtime <= mtime + 1;
    end
end




reg cache_ar_valid;

// ram的一些配置信息
wire [127:0]           RAM_Q [2-1:0]                                                            ;//读出的cache数据
wire                   RAM_CEN = 0                                                                      ;//为0有效，为1是无效（2个使能信号需要同时满足不然会读出随机数）使能信号控制
wire                   RAM_WEN[2-1:0]                                                           ;//为0是写使能1是读使能，读写控制hit是读数据
assign                 maskn   = (state == S_HIT) | (state == CLINT) ? {{8{w_w_strb_i[7]}},{8{w_w_strb_i[6]}},{8{w_w_strb_i[5]}},{8{w_w_strb_i[4]}},{8{w_w_strb_i[3]}},{8{w_w_strb_i[2]}},{8{w_w_strb_i[1]}},{8{w_w_strb_i[0]}}}
                                                               : 64'hffffffffffffffff                   ;//写掩码，目前是全位写，掩码在发送端处理了                                                               
wire                   shift   = (state == S_HIT) ? addr[3] : ~cache_rw_len_o                         ;//写使能的地址偏移shift为1代表高64位
wire [127:0]           RAM_BWEN= ~(shift ? {maskn,64'd0}  : {64'd0,maskn})                              ;//ram写掩码目前一样不用过多处理
wire [6-1:0] RAM_A   = (next_state == S_HIT)|(next_state == S_AW)&(~fence_stall_o) ? index_in : addr[9:4];//ram地址索引
wire [64-1:0]  wdata   = cache_r_valid_i&&cache_r_ready_o ? cache_r_data_i : w_data_i           ;
wire [127:0]           RAM_D   = shift ? {wdata,64'd0} : {64'd0,wdata}                                  ;//更新ram数据

wire write_enable = (state == S_R)&(cache_r_valid_i&cache_r_ready_o)|(state == S_HIT)&w_data_valid_i ? 0 : 1 ;
assign  RAM_WEN[0] = waynum ? 1 :write_enable;
assign  RAM_WEN[1] = waynum ? write_enable :1;

//实例化两块ram以及他们的命中逻辑的添加
generate
  genvar i;
  for(i=0;i<2;i=i+1)begin
  assign hit_wayflag[i]=((tag[i][index_in]==tag_in) && valid[i][index_in]);
    end
endgenerate

assign io_sram2_addr  =  RAM_A     ;
assign io_sram2_cen   =  RAM_CEN   ;
assign io_sram2_wen   =  RAM_WEN[0];
assign io_sram2_wmask =  RAM_BWEN  ;
assign io_sram2_wdata =  RAM_D     ;
assign RAM_Q[0]       =  io_sram2_rdata  ;
assign io_sram3_addr  =  RAM_A     ;
assign io_sram3_cen   =  RAM_CEN   ;
assign io_sram3_wen   =  RAM_WEN[1];
assign io_sram3_wmask =  RAM_BWEN  ;
assign io_sram3_wdata =  RAM_D     ;
assign RAM_Q[1]       =  io_sram3_rdata  ;

always@(posedge clk) begin
  if(rst)state<=S_IDLE;
  else state<=next_state;
end

// 一些ifu接口的输出信号中间态定义
reg                   r_data_valid;
reg [64-1:0]  r_data;

always@(*) begin
  case(state)
    S_IDLE:
      if(fence_i)begin
        next_state=FENCE_I;
      end
      else if(ar_valid_i&ar_ready_o|aw_valid_i&aw_ready_o)begin
            if(clint_addr) next_state=CLINT;
            else if(|hit_wayflag) next_state=S_HIT;
            else if(dirty[random][index_in]) next_state=S_AW;
            else next_state=S_AR;
          end
        else next_state=S_IDLE;

    S_HIT:if((r_data_ready_i&r_data_valid_o)|(b_ready_i&b_valid_o))next_state=S_IDLE;
      else next_state=S_HIT;

    S_AW:if(cache_aw_valid_o&cache_aw_ready_i)next_state=S_W;
      else next_state=S_AW;

    S_W:if(cache_w_ready_i&cache_w_valid_o&(cache_rw_len_o == 0))next_state=S_B;
      else next_state=S_W;

    S_B:if(cache_b_valid_i&cache_b_ready_o)begin
      if(fence_stall)next_state=FENCE_I;
      else next_state=S_AR;
    end
      else next_state=S_B;

    S_AR:if(cache_ar_valid_o&cache_ar_ready_i)next_state=S_R;
      else next_state=S_AR;

    S_R:if(cache_r_ready_o&cache_r_valid_i&(cache_rw_len_o == 0))begin
      if(~rw_control&r_data_ready_i) next_state = S_IDLE;
      else next_state=S_HIT;
    end
      else next_state=S_R;

    CLINT:if((r_data_ready_i&r_data_valid_o)|(b_ready_i&b_valid_o))next_state=S_IDLE;
      else next_state=CLINT;

		FENCE_I:if(dirty[fence_cnt[6]][fence_cnt[5:0]])next_state=S_AW;
			else if(fence_cnt[7])next_state=S_IDLE;
			else next_state=FENCE_I;

    default:next_state=S_IDLE;
  endcase
end

always@(posedge clk)begin
  if(rst)begin
    //初始化对比项
    for( j=0;j<2;j=j+1)begin
      for( k=0;k<64;k=k+1)begin
          tag[j][k]  <= 22'b0;
	  			dirty[j][k]<= 1'b0;
	  			valid[j][k]<= 1'b0;
      end
    end
    mtimecmp                      <= 0                                     ;
    rw_control                    <= 0                                     ;
		ar_ready_o                    <= 0                                     ;
    aw_ready_o                    <= 0                                     ;
		r_data_valid                  <= 0                                     ;
		r_data                        <= 0                                     ;
    w_data_ready_o                <= 0                                     ;
    b_valid_o                     <= 0                                     ;
    b_resp_o                      <= 0                                     ;
    cache_ar_valid                <= 0                                     ;
    cache_ar_addr_o               <= 0                                     ;
		cache_r_ready_o               <= 0                                     ;
    waynum                        <= 0                                     ;
    addr                          <= 0                                     ;
    cache_rw_len_o                <= 0                                     ;
    fence_stall                   <= 0                                     ;
    fence_cnt                     <= 0                                     ;
    cache_w_last_o                <= 0                                     ;
    cache_w_data_o                <= 0                                     ;
    cache_aw_addr_o               <= 0;
    cache_aw_valid_o              <= 0;
    cache_b_ready_o               <= 0                                     ;
    cache_w_strb_o                <= 0                                 ;
    cache_w_valid_o               <= 0                                     ;

  end
  else begin
    case(state)
      S_IDLE:
        if(next_state==FENCE_I)begin
          fence_stall<= 1                                                  ;
          fence_cnt  <= 0                                                  ;
          addr       <= 0                                                  ;
        end
        else if(next_state==CLINT)begin
					ar_ready_o              <= 0                                     ;
          aw_ready_o              <= 0                                     ;
          if(aw_valid_i&aw_ready_o) begin
          rw_control              <= 1                                     ;
          w_data_ready_o          <= 1                                     ;
          end
          else begin
          r_data_valid            <= 1                                     ;
          r_data                  <= ar_addr_i == 32'h2004000 ? mtimecmp : mtime;
          end
        end
        else if(next_state==S_HIT)begin
					ar_ready_o              <= 0                                     ;
          aw_ready_o              <= 0                                     ;
          r_data_valid            <= 0                                     ; 
          waynum                  <= hit_waynum_i                          ;
          addr                    <= rw_addr_i[31:0]                     ;
          if(aw_valid_i&aw_ready_o) begin
          rw_control              <= 1                                     ;
          w_data_ready_o          <= 1                                     ;
          end
        end
        else if(next_state==S_AR)begin
//          icache_wait()                                                    ;//多跑2个周期平衡
					ar_ready_o              <= 0                                     ;
          aw_ready_o              <= 0                                     ;
          waynum                  <= random                                ;
          addr                    <= rw_addr_i[31:0]                     ;
          valid[random][index_in] <= 0                                     ;
          tag[random][index_in]   <= rw_addr_i[31:10]                  ;
          cache_ar_valid          <= 1                                     ;
          cache_ar_addr_o         <= {rw_addr_i[31:4],OFFSET0}      ;
          cache_rw_len_o          <= 1                                     ;
          if(aw_valid_i&aw_ready_o) begin
          rw_control              <= 1                                     ;
          w_data_ready_o          <= 0                                     ;
          end
        end
        else if(next_state==S_AW)begin
//          icache_wait()                                                  ;//多跑2个周期平衡
					ar_ready_o              <= 0                                     ;
          aw_ready_o              <= 0                                     ;
          waynum                  <= random                                ;
          addr                    <= rw_addr_i[31:0]                     ;
          valid[random][index_in] <= 0                                     ;
          if(aw_valid_i&aw_ready_o) begin
          rw_control              <= 1                                     ;
          end

          cache_aw_valid_o        <= 1;
          cache_aw_addr_o         <= {tag[random][index_in],index_in,OFFSET0};
          cache_rw_len_o          <= 1                                     ;
        end
        else begin
					ar_ready_o              <= 1                                     ;
          cache_aw_addr_o         <= 0;
          cache_ar_addr_o         <= 0;

          aw_ready_o              <= 1                                     ;
					r_data_valid            <= 0                                     ;
					cache_r_ready_o         <= 0                                     ;
        end

      S_HIT:if(next_state==S_IDLE)begin
          rw_control              <= 0                                     ;
					ar_ready_o              <= 1                                     ;
          aw_ready_o              <= 1                                     ;
					r_data_valid            <= 0                                     ;
          waynum                  <= 0                                     ;
          r_data                  <= 0                                     ;
          b_valid_o               <= 0                                     ;
      end
      else if(rw_control) begin
         if(w_data_valid_i) begin
         dirty[waynum][index]     <= 1                                     ;
         w_data_ready_o           <= 0                                     ;
         b_valid_o                <= 1                                     ;
         b_resp_o                 <= 0                                     ;
         end
      end
      else if(~rw_control) begin
          r_data_valid            <= 1                                     ; 
          r_data                  <= addr[3] ? RAM_Q[waynum][127:64] : RAM_Q[waynum][63:0];
      end

      S_AW:if(next_state==S_W)begin
          cache_aw_valid_o        <= 0                                     ;
          cache_w_valid_o         <= 1                                     ;
          cache_w_strb_o          <= 8'hff                                 ;
          cache_w_data_o          <= RAM_Q[waynum][63:0]                   ;
        end
        else begin
          cache_aw_valid_o        <= 1                                     ; 
          cache_w_valid_o         <= 0                                     ;
          cache_w_strb_o          <= 8'hff                                 ;
          cache_w_data_o          <= RAM_Q[waynum][63:0]                   ;
        end

      S_W:if(cache_w_ready_i&cache_w_valid_o&(cache_rw_len_o != 0))begin
          cache_rw_len_o <= cache_rw_len_o -1                              ;
          cache_w_data_o <= RAM_Q[waynum][127:64]                          ;
          cache_w_last_o          <= 1                                     ;
          end
          else if(next_state==S_B)begin
          cache_w_last_o          <= 0                                     ;
          cache_w_valid_o         <= 0                                     ;
          cache_b_ready_o         <= 1                                     ;
          dirty[waynum][index]    <= 0                                     ;
          valid[waynum][index]    <= 0                                     ;
          tag[waynum][index]      <= addr[31:10]                       ;
            end

      S_B:if(next_state==FENCE_I)begin
          fence_cnt               <= fence_cnt + 1                         ;
          cache_b_ready_o         <= 0                                     ;
          cache_w_last_o          <= 0                                     ;
        end
          else if(next_state==S_AR)begin
          cache_w_last_o          <= 0                                     ;
          cache_b_ready_o         <= 0                                     ;
          cache_ar_valid          <= 1                                     ;
          cache_ar_addr_o         <= {addr[31:4],OFFSET0}           ;
          cache_rw_len_o          <= 1                                     ;
        end

      S_AR:if(next_state==S_R)begin
          cache_ar_valid          <= 0                                     ;
          cache_r_ready_o         <= 1                                     ;
          end

      S_R:if(cache_r_valid_i&cache_r_ready_o&(cache_rw_len_o != 0))begin
              cache_rw_len_o <= cache_rw_len_o -1;
              r_data         <= cache_r_data_i;
          end
          else if(next_state==S_IDLE)begin
					    ar_ready_o          <= 1                                  ;
              aw_ready_o          <= 1                                  ;
					    r_data_valid        <= 0                                  ;
              waynum              <= 0                                  ;
              r_data              <= 0                                  ;
              cache_r_ready_o     <= 0                                  ;
              valid[waynum][index]<= 1                                  ; 
            end
          else if(next_state==S_HIT)begin
              cache_r_ready_o     <= 0                                  ;
              valid[waynum][index]<= 1                                  ; 
              if(rw_control) begin
              w_data_ready_o      <= 1                                  ;
              end
              else begin
              r_data              <= addr[3] ? cache_r_data_i : r_data  ; 
              r_data_valid        <= 1                                  ;
              end
            end
      CLINT:
        if(next_state==S_IDLE)begin
          rw_control              <= 0                                     ;
					ar_ready_o              <= 1                                     ;
          aw_ready_o              <= 1                                     ;
					r_data_valid            <= 0                                     ;
          r_data                  <= 0                                     ;
          b_valid_o               <= 0                                     ;
        end
        else if(rw_control) begin
           if(w_data_valid_i) begin
            if(aw_addr_i == 32'h2004000)begin
            mtimecmp                 <= (w_data_i&maskn)|(mtimecmp&(~maskn))  ;
            end
            else mtimecmp <= mtimecmp;
           w_data_ready_o           <= 0                                     ;
           b_valid_o                <= 1                                     ;
           b_resp_o                 <= 0                                     ;
           end
        end
      FENCE_I:
        if(next_state==S_AW)begin
          waynum                     <= fence_cnt[6]                          ;
          addr                       <= {tag[fence_cnt[6]][fence_cnt[5:0]],fence_cnt[5:0],OFFSET0}    ;
          cache_aw_addr_o            <= {tag[fence_cnt[6]][fence_cnt[5:0]],fence_cnt[5:0],OFFSET0};
          cache_rw_len_o             <= 1                                     ;
        end
        else if(next_state==S_IDLE) begin
          fence_stall<= 0                                                  ;
          fence_cnt  <= 0                                                  ;
          addr       <= 0                                                  ;
        end
        else begin
          valid[fence_cnt[6]][fence_cnt[5:0]] <= 0                         ;
          fence_cnt  <= fence_cnt + 1                                      ;
        end

      default:begin
      end
    endcase
  end
end



//axi的一些需要适配仲裁器的信号

assign cache_ar_valid_o = cache_ar_valid;

//与外部ifu访问的改善信号
assign r_data_valid_o  = cache_r_ready_o&cache_r_valid_i&(cache_rw_len_o == 0)& ~rw_control|(state == S_HIT)&(~rw_control) ? 1 : r_data_valid;
assign r_data_o        = cache_r_ready_o&cache_r_valid_i&(cache_rw_len_o == 0)& ~rw_control|(state == S_HIT)&(~rw_control) ? ((state == S_HIT) ? (addr[3] ? RAM_Q[waynum][127:64] : RAM_Q[waynum][63:0]) : (addr[3] ? cache_r_data_i : r_data)) : r_data;
assign fence_stall_o   = fence_stall | fence_i;
//仿真程序接入
/*
always@(posedge clk) begin
  if(RAM_A == 6'h1b &&~RAM_WEN[0]) begin
  $display("rwaddr   = %h\n\
     w_data_i       = %h\n\
     cache_r_data_i       = %h\n\
    ",rw_addr_i|addr,w_data_i,cache_r_data_i );
  end
end
*/
endmodule

module ysyx_22050019_EX_MEM (
    input              clk                 ,
    input              rst_n               ,
    input     [63:0]   pc_i                ,
    input     [31:0]   inst_i              ,
    input     [63:0]   result_i            ,
    input     [63:0]   wdata_exu_reg_i     ,
    input              ram_we_i            ,
    input     [63:0]   ram_wdata_i         ,
    input     [3:0]    mem_w_wdth_i        ,
    input              ram_re_i            ,
    input     [5:0]    mem_r_wdth_i        ,
    input              reg_we_i            ,
    input     [4:0]    reg_waddr_i         ,
    input     [63:0]   wdate_csr_reg_i     ,
`ifdef ysyx_22050019_dpic
    input     [63:0]   csr_regs_diff_i[3:0],
    output    [63:0]   csr_regs_diff_o[3:0],
`endif
    input              commite_i           ,
    input             fence_stall_i       ,

    /* control */
    input              ex_mem_stall_i      ,
    input  wire        mem_wb_stall_i      ,

    output reg         commite_o           ,
    output reg         fence_stall_o       ,
    output reg[63:0]   pc_o                ,
    output reg[31:0]   inst_o              ,
    output reg[63:0]   result_o            ,
    output reg[63:0]   wdata_exu_reg_o     ,
    output reg         ram_we_o            ,
    output reg[63:0]   ram_wdata_o         ,
    output reg[3:0]    mem_w_wdth_o        ,
    output reg         ram_re_o            ,
    output reg[5:0]    mem_r_wdth_o        ,
    output reg         reg_we_o            ,
    output reg[4:0]    reg_waddr_o         ,
    output reg[63:0]   wdate_csr_reg_o     

);

  always @(posedge clk) begin
    if (rst_n) begin
        result_o        <= 0;   
        wdata_exu_reg_o <= 0;   
        ram_we_o        <= 0;   
        ram_wdata_o     <= 0;   
        mem_w_wdth_o    <= 0;   
        ram_re_o        <= 0;   
        mem_r_wdth_o    <= 0;   
        reg_we_o        <= 0;   
        reg_waddr_o     <= 0;   
        wdate_csr_reg_o <= 0;  
        fence_stall_o   <= 0;
    end
    else if (ex_mem_stall_i && (~mem_wb_stall_i)) begin
        result_o        <= 0;   
        wdata_exu_reg_o <= 0;   
        ram_we_o        <= 0;   
        ram_wdata_o     <= 0;   
        mem_w_wdth_o    <= mem_w_wdth_o;   
        ram_re_o        <= 0;   
        mem_r_wdth_o    <= mem_r_wdth_o;   
        reg_we_o        <= 0;   
        reg_waddr_o     <= 0;   
        wdate_csr_reg_o <= 0;  
        fence_stall_o   <= 0;
    end
    else if (~ex_mem_stall_i) begin
        result_o        <= result_i       ;   
        wdata_exu_reg_o <= wdata_exu_reg_i;   
        ram_we_o        <= ram_we_i       ;   
        ram_wdata_o     <= ram_wdata_i    ;   
        mem_w_wdth_o    <= mem_w_wdth_i   ;   
        ram_re_o        <= ram_re_i       ;   
        mem_r_wdth_o    <= mem_r_wdth_i   ;   
        reg_we_o        <= reg_we_i       ;   
        reg_waddr_o     <= reg_waddr_i    ;   
        wdate_csr_reg_o <= wdate_csr_reg_i;  
        fence_stall_o   <= fence_stall_i  ;
    end
    else begin
        result_o        <= result_o       ;   
        wdata_exu_reg_o <= wdata_exu_reg_o;   
        ram_we_o        <= ram_we_o       ;   
        ram_wdata_o     <= ram_wdata_o    ;   
        mem_w_wdth_o    <= mem_w_wdth_o   ;   
        ram_re_o        <= ram_re_o       ;   
        mem_r_wdth_o    <= mem_r_wdth_o   ;   
        reg_we_o        <= reg_we_o       ;   
        reg_waddr_o     <= reg_waddr_o    ;   
        wdate_csr_reg_o <= wdate_csr_reg_o;  
        fence_stall_o   <= fence_stall_o  ;
    end

  end
//======================================
//仿真信号

`ifdef ysyx_22050019_dpic
reg [63:0] mtvec  ;
reg [63:0] mepc   ;
reg [63:0] mstatus;
reg [63:0] mcause ;
assign csr_regs_diff_o[0] = mtvec  ;
assign csr_regs_diff_o[1] = mepc   ;
assign csr_regs_diff_o[2] = mstatus;
assign csr_regs_diff_o[3] = mcause ;
`endif
  always @(posedge clk) begin
    if (rst_n) begin
        pc_o             <= 0                ;
        inst_o           <= 0                ;
        commite_o        <= 0                ;
`ifdef ysyx_22050019_dpic
        mtvec            <= 0                ;
        mepc             <= 0                ;
        mstatus          <= 0                ;
        mcause           <= 0                ;
`endif

    end
    else if (ex_mem_stall_i && (~mem_wb_stall_i)) begin
        pc_o             <= pc_o              ;
        inst_o           <= inst_o            ;
        commite_o        <= 1                 ;
`ifdef ysyx_22050019_dpic
        mtvec            <= mtvec             ;
        mepc             <= mepc              ;
        mstatus          <= mstatus           ;
        mcause           <= mcause            ;
`endif
    end
    else if (~ex_mem_stall_i) begin
        pc_o            <= pc_i              ;
        inst_o          <= inst_i            ;
        commite_o       <= commite_i         ;
`ifdef ysyx_22050019_dpic
        mtvec           <= csr_regs_diff_i[0];
        mepc            <= csr_regs_diff_i[1];
        mstatus         <= csr_regs_diff_i[2];
        mcause          <= csr_regs_diff_i[3];
`endif

    end
    else begin
        pc_o            <= pc_o              ;
        inst_o          <= inst_o            ;
        commite_o       <= commite_o         ;
`ifdef ysyx_22050019_dpic
        mtvec           <= mtvec             ;
        mepc            <= mepc              ;
        mstatus         <= mstatus           ;
        mcause          <= mcause            ;
`endif

    end

  end


endmodule


module ysyx_22050019_EXU(
  input           clk,
  input           rst_n,
  input           wen_i,
  input [4:0]     waddr_i,
  input [`ysyx_22050019_alu_len:0]  alu_sel,

  input [63:0]    op1,
  input [63:0]    op2,
  input           lsu_stall,

  output [63:0]   result,
  output          alu_stall,
  output          exu_wen  ,
  output [4:0]    exu_waddr, 
  output [63:0]   wdata
);

wire wen;
ysyx_22050019_alu alu(
  .clk  (clk) ,
  .rst_n(rst_n) ,
  .op_1(op1),
  .op_2(op2),
  .alu_sel(alu_sel),
  .lsu_stall(lsu_stall),
  
  .alu_stall(alu_stall),
  .alu_ok(wen),
  .result(result)
);

//reg_control
reg[4:0] waddr;
always @(posedge clk)begin
  if(rst_n) waddr <= 0;
  else if(|alu_sel [33:21])
            waddr <= waddr_i;
  else if(exu_wen)
            waddr <= 0;
end

assign wdata    = result ;
assign exu_waddr= alu_stall ? 0 : (wen ? waddr : 0) | waddr_i;
assign exu_wen  = alu_stall ? 0 : wen_i | wen;


endmodule


module ysyx_22050019_fetch_buffer(
  input                   clk         , 
  input                   rst_n       ,
  // axi-i_cahce
  input                   ar_ready_i  ,
  output                  ar_valid_o  ,
  output [31:0]           ar_addr_o   ,

  input                   r_valid_i   ,
  input  [127:0]          r_data_i    , 
  input  [1:0]            r_resp_i    ,  
  output                  r_ready_o   ,

  // ifu-fetch_buffer
  // control
//  input                   jmp_flush_i ,
  input                   stall_ib    ,

  input  [31:0]           pc_i        ,

//  output                  flash,
  output                  inst_valid_o,
  output [31:0]           inst_o          
);
// 状态准备
localparam IDLE       = 2'd0;
localparam WAIT_READY = 2'd1;
localparam FAIL_WAIT  = 2'd2;
reg  [1:0]state_reg;
reg  [1:0]next_state;
reg rready;
reg ar_valid;
//reg jmp_flage;
reg fail_trans;
reg [31:0] pc_reg;
//=========================  
// 判断输入pc是否相等的逻辑
// buffer pc
//reg [31:0]buffer_pc; //只保存pc在cache line的块映射，也就是说对于低4位偏移拉0来对比
reg pc_changed ;
// 根据pc_changed进行读地址使能变化的模块
always @ (posedge clk) begin
    if(rst_n)begin
        pc_changed <= 0;
    end
    else if(pc_reg != pc_i[31:0]) begin
        pc_changed <= 1;
    end
    else if(inst_valid_o)begin
        pc_changed <= 0 ;
    end
end
// 根据buffer状态和pc输出指令和指令有效使能
assign inst_valid_o = r_valid_i & r_ready_o & next_state != FAIL_WAIT;
assign inst_o       = inst_valid_o ? (pc_reg[3] ? pc_reg [2] ? r_data_i[127:96] : r_data_i[95:64] : pc_reg [2] ? r_data_i[63:32] : r_data_i[31:0]) : 0;

// axi_interface
assign ar_valid_o   = state_reg == IDLE && pc_changed;
assign ar_addr_o    = pc_reg ;

assign r_ready_o    = rready;

//=========================  
// 对于flash外设访问的接口更改
//assign flash=0;

/*
  // 读的状态机
always @ (posedge clk) begin
    if(rst_n)begin
        buffer_pc <= 0;
    end
    else if((state_reg == IDLE) && (buffer_pc != pc_reg[31:0]) && inst_valid_o) begin
        buffer_pc <= pc_reg[31:0];
    end
    else begin
        buffer_pc <= buffer_pc ;
    end
end
*/
reg stall_reg;
  always @(posedge clk) begin
    if (rst_n) begin
      stall_reg <= 0;
      pc_reg    <= 0;
    end else begin
      stall_reg <= stall_ib;
      pc_reg    <= pc_i;
    end
  end
//=========================  
//=========================  
// AXI buffer <=> icache交流接口逻辑
// AXI - interface

  // 状态转移
  always @(posedge clk) begin
    if (rst_n) begin
      state_reg <= IDLE;
    end else begin
      state_reg <= next_state;
    end
  end

 always@(*) begin
  if(rst_n) next_state = IDLE;
  else case(state_reg)
    IDLE :
      if(ar_ready_i && ar_valid_o) begin 
        next_state = WAIT_READY ; 
        end
      else next_state = IDLE;

    WAIT_READY : 
      if(r_valid_i && r_ready_o) begin 
        if (stall_ib||stall_reg||fail_trans)begin
        next_state = FAIL_WAIT; 
        end
        else next_state = IDLE; 
        end
      else next_state = WAIT_READY;

    FAIL_WAIT : 
      if(~stall_ib) next_state = IDLE;
      else next_state = FAIL_WAIT;

    default : next_state = IDLE;
  endcase
end

always@(posedge clk)begin
  if(rst_n)begin
        rready          <= 1'b0;
        fail_trans      <= 0;
  end
  else begin
    case(state_reg)
      IDLE:
      if(next_state==WAIT_READY) begin
        fail_trans      <= stall_ib||stall_reg;
        rready          <= 1'b1;
      end
      else begin
        rready          <= 1'b0;
      end

      WAIT_READY:begin  
      if(next_state==FAIL_WAIT)begin
        rready          <= 1'b0;
      end   
      else if(next_state==IDLE)begin
        rready          <= 1'b0;
      end
      else begin 
        rready          <= 1;
      end
      end

      FAIL_WAIT:begin  
      if(next_state==IDLE)begin
        rready          <= 1'b0;
        fail_trans      <= 0;
      end
      end

      default:begin
      end
    endcase
  end
end

endmodule
/*
module ysyx_22050019_forwarding (

  input    [4:0] reg_raddr_1_id     ,
  input    [4:0] reg_raddr_2_id     ,
  input    [4:0] reg_waddr_exu      ,
  input    [4:0] reg_waddr_lsu      ,
  input          reg_wen_exu        ,
  input          reg_wen_lsu        ,
  input    [63:0]reg_wen_wdata_exu_i,
  input    [63:0]reg_wen_wdata_lsu_i,

  input    [63:0]reg_r_data1_id_i   ,
  input    [63:0]reg_r_data2_id_i   ,

//  output         forwarding_stall_o ,
  output   [63:0]reg_r_data1_id__o  ,
  output   [63:0]reg_r_data2_id__o  
);

  // 对于将lsu写wb的写寄存器通路与来自exu写的进行了合并，这样如果exu拉下的数据的前递，在lsu阶段有机会补上
  //reg_wen_lsu && 这里的删除是因为两周期流水线会出现exu遗漏前递的情况发生，删除了这个可以让exu遗漏的在lsu补上，前提条件是对于waddr和wdata在发出时进行使能控制，减少乱传可能性
  // rs1 exu前推
  wire ForwardA_exu = reg_wen_exu && (reg_waddr_exu != 0) && (reg_waddr_exu == reg_raddr_1_id);
  // rs1 lsu前推
  wire ForwardA_lsu = reg_wen_lsu && (reg_waddr_lsu != 0) && (!(reg_wen_exu && (reg_waddr_exu != 0) && (reg_waddr_exu == reg_raddr_1_id))) && (reg_waddr_lsu == reg_raddr_1_id);

  // rs2 exu前推
  wire ForwardB_exu = reg_wen_exu && (reg_waddr_exu != 0) && (reg_waddr_exu == reg_raddr_2_id);
  // rs2 lsu前推
  wire ForwardB_lsu = reg_wen_lsu && (reg_waddr_lsu != 0) && (!(reg_wen_exu && (reg_waddr_exu != 0) && (reg_waddr_exu == reg_raddr_2_id))) && (reg_waddr_lsu == reg_raddr_2_id);

// 10-exu前递出、01-lsu前递，00-原来值，11-在上面的逻辑中不会出现因为两个使能是互斥的
wire [1:0]raddr1_sel   = {ForwardA_exu ,ForwardA_lsu};
ysyx_22050019_mux #( .NR_KEY(3), .KEY_LEN(2), .DATA_LEN(64) ) mux_r_data1
(
  .key         (raddr1_sel), //键
  .default_out (64'b0),
  .lut         ({2'b10,reg_wen_wdata_exu_i,
                 2'b01,reg_wen_wdata_lsu_i,
                 2'b00,reg_r_data1_id_i 
                 }), //键和输出的表           
  .out         (reg_r_data1_id__o)  //输出
);

//op2_sel
wire [1:0]raddr2_sel   = {ForwardB_exu ,ForwardB_lsu};
ysyx_22050019_mux #( .NR_KEY(3), .KEY_LEN(2), .DATA_LEN(64)) mux_r_data2
(
  .key         (raddr2_sel), //键
  .default_out (64'b0),
  .lut         ({
                 2'b10,reg_wen_wdata_exu_i,
                 2'b01,reg_wen_wdata_lsu_i,
                 2'b00,reg_r_data2_id_i 
                 }),         
  .out         (reg_r_data2_id__o)  //输出
);


// lsu对于idu的暂停（插入nop）这里的操作是提前阻塞if_id然后把l指令传下去给lsu执行（传递过后这个信号就拉低了类似一个补充信号）
assign forwarding_stall_o = ~reg_wen_exu & (reg_waddr_exu != 0) && ((reg_waddr_exu == reg_raddr_1_id) || (reg_waddr_exu == reg_raddr_2_id));

//assign forwarding_stall_o = 0;
assign reg_r_data1_id__o = reg_r_data1_id_i;
assign reg_r_data2_id__o = reg_r_data2_id_i;
endmodule
*/
/*
 * icache - config_Fire
 * 只能读取
 *
 *  |     Tag     |     Index     |          Offset          |
 *  |             |               |                          |
 * 31            10|9            4|3                         0
 * 
 * 每行共2字即16字节即128位，2路组相联
 * 共128行，总大小为8KiB

 * 物理地址总长为32位
 * 每一行字长合计16字节 - Byte  4位
 * 共128行,2路组相连   - Index 6位
 * Tag = 32 - 3 - 6  = 22位
 */
module ysyx_22050019_icache(
  input  clk                                             ,
  input  rst                                             ,
 
  input                              fence_i             ,  
  input                              ar_valid_i          ,         
  output reg                         ar_ready_o          ,     
  input     [32-1:0]       ar_addr_i           ,             
  output                             r_data_valid_o      ,     
  input                              r_data_ready_i      ,
  input     [1:0]                    r_resp_i            ,     
  output    [127:0]                  r_data_o            ,  
  
  output [5:0]    io_sram0_addr     ,
  output          io_sram0_cen      ,
  output          io_sram0_wen      ,
  output [127:0]  io_sram0_wmask    ,  
  output [127:0]  io_sram0_wdata    ,  
  input  [127:0]  io_sram0_rdata    ,  
  output [5:0]    io_sram1_addr     ,
  output          io_sram1_cen      ,
  output          io_sram1_wen      ,
  output [127:0]  io_sram1_wmask    ,  
  output [127:0]  io_sram1_wdata    ,  
  input  [127:0]  io_sram1_rdata    ,  

  output                             cache_ar_valid_o    ,       
  input                              cache_ar_ready_i    ,     
  output    [32-1:0]         cache_ar_addr_o     ,
  output                             cache_ar_len_o      ,          
  output reg                         cache_r_ready_o     ,     
  input                              cache_r_valid_i     ,
  input     [1:0]                    cache_r_resp_i      ,      
  input     [64-1:0]       cache_r_data_i
);
localparam S_IDLE =0;
localparam S_HIT  =1;
localparam S_AR   =2;
localparam S_R    =3;
localparam FENCE_I=4;

reg[15:0] state;
reg[15:0] next_state;
// 保存地址，miss后的写数据，偏移寄存器
reg [32-1:0]   addr  ;
wire[6-1:0]  index = addr[9:4];

// tag和标记位的寄存器值
reg [22-1:0] tag  [2-1:0][64-1:0];
reg                 valid[2-1:0][64-1:0];

// wire类型传入的地址解析
wire[22-1:0]    tag_in  = ar_addr_i[31:10]    ;
wire[6-1:0]  index_in= ar_addr_i[9:4];
wire[4-1:0] OFFSET0 = 0                       ;//4'b0对于这里是持有怀疑态度的

// 命中路的判断逻辑      0-1 两路
wire[2-1:0]hit_wayflag;
wire[1-1:0]hit_waynum_i=hit_wayflag==2'b01 ? 0
                          :hit_wayflag==2'b10 ? 1
                          :0;
reg[1-1:0]waynum;
reg[1-1:0]random;
always@(posedge clk)begin//随机替换的替换策略
  if(rst)random<=0;
  else random<=random+1;
end

// 一些ifu接口的输出信号中间态定义
reg                   r_data_valid;
reg [127:0]           r_data;
// 一些总线接口的输出信号中间态定义
reg                   cache_ar_valid; 
reg [32-1:0]  cache_ar_addr;
reg                   cache_ar_len;
reg                   fence_reg;
// ram的一些配置信息
wire [127:0]           RAM_Q [2-1:0]                                            ;//读出的cache数据
wire                   RAM_CEN = 0                                                      ;//为0有效，为1是无效（2个使能信号需要同时满足不然会读出随机数）使能信号控制
wire                   RAM_WEN[2-1:0]                                           ;//为0是写使能1是读使能，读写控制hit是读数据
wire [64-1:0]maskn   = 64'hffffffffffffffff                                   ;//写掩码，目前是全位写，掩码在发送端处理了
wire                   shift   = ~cache_ar_len                                          ;//写使能的地址偏移shift为1代表高64位
wire [127:0]           RAM_BWEN= ~(shift ? {maskn,64'd0}  : {64'd0,maskn})              ;//ram写掩码目前一样不用过多处理
wire [6-1:0] RAM_A   = (next_state == S_HIT) ? index_in : addr[9:4]     ;//ram地址索引
wire [127:0]           RAM_D   = shift ? {cache_r_data_i,64'd0} : {64'd0,cache_r_data_i};//更新ram数据

wire    write_enable = cache_r_valid_i&cache_r_ready_o ? 0 : 1 ;
assign  RAM_WEN[0] = waynum ? 1 :write_enable;
assign  RAM_WEN[1] = waynum ? write_enable :1;

//实例化两块ram以及他们的命中逻辑的添加
generate
  genvar i;
  for(i=0;i<2;i=i+1)begin
  assign hit_wayflag[i]=((tag[i][index_in]==tag_in)&&valid[i][index_in]);
    end
endgenerate
assign io_sram0_addr  =  RAM_A     ;
assign io_sram0_cen   =  RAM_CEN   ;
assign io_sram0_wen   =  RAM_WEN[0];
assign io_sram0_wmask =  RAM_BWEN  ;
assign io_sram0_wdata =  RAM_D     ;
assign RAM_Q[0]       =  io_sram0_rdata  ;
assign io_sram1_addr  =  RAM_A     ;
assign io_sram1_cen   =  RAM_CEN   ;
assign io_sram1_wen   =  RAM_WEN[1];
assign io_sram1_wmask =  RAM_BWEN  ;
assign io_sram1_wdata =  RAM_D     ;
assign RAM_Q[1]       =  io_sram1_rdata  ;

always@(posedge clk) begin
  if(rst)begin
    state<=S_IDLE;
    fence_reg <= 0;
  end
  else begin
  state<=next_state;
  fence_reg <= fence_i;
  end
end


always@(*) begin
  if(rst)next_state=S_IDLE;
  else case(state)
    S_IDLE:
      if(ar_valid_i&ar_ready_o)begin
            if(|hit_wayflag)next_state=S_HIT;
            else next_state=S_AR;
          end
      else next_state=S_IDLE;

    S_HIT:if(r_data_ready_i&r_data_valid_o)next_state=S_IDLE;
      else next_state=S_HIT;

    S_AR:if(cache_ar_valid&cache_ar_ready_i)next_state=S_R;
      else next_state=S_AR;

    S_R:if(cache_r_ready_o&cache_r_valid_i&(cache_ar_len == 0))begin
      if(r_data_ready_i&r_data_valid_o) next_state=S_IDLE;
      else next_state=S_HIT;
    end
      else next_state=S_R;

    default:next_state=S_IDLE;
  endcase
end
integer j;
integer k;
always@(posedge clk)begin
  if(rst)begin
		ar_ready_o          <= 0;
		r_data_valid        <= 0;
		r_data              <= 0;
    cache_ar_valid      <= 0;
    cache_ar_addr       <= 0;
    cache_ar_len        <= 0;
		cache_r_ready_o     <= 0;
    waynum              <= 0;
    addr                <= 0;
    for( j=0;j<2;j=j+1)begin
      for( k=0;k<64;k=k+1)begin
          tag[j][k]<=0;
	  			valid[j][k]<=0;
      end
    end
  end
  else begin
    case(state)
      S_IDLE:if(next_state==S_HIT)begin
					ar_ready_o              <= 0                     ;
          r_data_valid            <= 0                     ; 
          waynum                  <= hit_waynum_i          ;
          addr                    <= ar_addr_i[31 : 0]   ;
        end
        else if(next_state==S_R)begin
					ar_ready_o              <= 0;
          waynum                  <= random;
          addr                    <= ar_addr_i[31 : 0]   ;
          cache_ar_len            <= 1;
          valid[random][index_in] <= 0;
          tag[random][index_in]   <= ar_addr_i[31:10];
          cache_r_ready_o         <= 1;
        end
        else if(next_state==S_AR)begin
					ar_ready_o              <= 0;
          waynum                  <= random;
          addr                    <= ar_addr_i[31 : 0]   ;
          cache_ar_len            <= 1;
          valid[random][index_in] <= 0;
          tag[random][index_in]   <= ar_addr_i[31:10];
          cache_ar_valid          <= 1;
          cache_ar_addr           <= {ar_addr_i[31:4],OFFSET0};
        end
        else begin
          if(fence_reg)begin
            for( j=0;j<2;j=j+1)begin
              for( k=0;k<64;k=k+1)begin
                  tag[j][k]<=0;
	          			valid[j][k]<=0;
              end
            end
          end
					ar_ready_o              <= 1;
					r_data_valid            <= 0;
					cache_r_ready_o         <= 0;
        end

      S_HIT:if(next_state==S_IDLE)begin
					ar_ready_o          <= 1;
					r_data_valid        <= 0;
          waynum              <= 0;
          r_data              <= 0;
      end
      else if(r_data_valid)begin
        //避免没写入缓存的数据短暂污染输出数据-这个原因是取出数据后接收方没准备好造成的切换的漏洞
          r_data_valid           <= 1            ; 
      end
      else begin
          r_data_valid            <= 1            ; 
          r_data                  <= RAM_Q[waynum];
      end

      S_AR:if(next_state==S_R)begin
          cache_ar_valid   <= 0;
          cache_r_ready_o  <= 1;
          end

      S_R:if(cache_r_valid_i&cache_r_ready_o&(cache_ar_len != 0))begin
              cache_ar_len   <= cache_ar_len -1;
              r_data         <= {64'b0,cache_r_data_i};
          end
          else if(next_state==S_IDLE)begin
					    ar_ready_o          <= 1                                  ;
					    r_data_valid        <= 0                                  ;
              waynum              <= 0                                  ;
              r_data              <= 0                                  ;
              cache_r_ready_o     <= 0                                  ;
              valid[waynum][index]<= 1                                  ; 
            end
          else if(next_state==S_HIT)begin
              cache_r_ready_o     <= 0                                  ;
              valid[waynum][index]<= 1                                  ;
              r_data              <= {cache_r_data_i,r_data[63:0]}    ;  
              r_data_valid        <= 1                                  ;
            end

      default:begin
      end
    endcase
  end
end
//与外部ifu访问的改善信号
assign r_data_valid_o  = cache_r_ready_o&cache_r_valid_i&(cache_ar_len == 0)|(state == S_HIT) ? 1 : r_data_valid;
assign r_data_o        = cache_r_ready_o&cache_r_valid_i&(cache_ar_len == 0)|(state == S_HIT) ? ((state == S_HIT) ? (r_data_valid ? r_data : RAM_Q[waynum]) : {cache_r_data_i,r_data[63:0]}) : r_data;
//与外部axi访问的改善信号
assign cache_ar_valid_o = cache_ar_valid  ;//用选择器也行，但这里的逻辑这么写视乎能省一点地方
assign cache_ar_addr_o  = cache_ar_addr;
assign cache_ar_len_o   = cache_ar_len;
endmodule

module ysyx_22050019_ID_EX (
    input             clk                 ,
    input             rst_n               ,
    input     [63:0]  pc_i                ,
    input     [31:0]  inst_i              ,
    input             ram_we_i            ,
    input     [63:0]  ram_wdata_i         ,
    input     [3:0]   mem_w_wdth_i        ,
    input             ram_re_i            ,
    input     [5:0]   mem_r_wdth_i        ,
    input     [63:0]  op1_i               ,
    input     [63:0]  op2_i               ,
    input             reg_we_i            ,
    input     [4:0]   reg_waddr_i         ,
    input     [`ysyx_22050019_alu_len:0]alu_sel_i           ,
    input     [63:0]  wdate_csr_reg_i     ,

    input             commite_i           ,
    input             fence_stall_i       ,
`ifdef ysyx_22050019_dpic
    input     [63:0]  csr_regs_diff_i[3:0],
    output    [63:0]  csr_regs_diff_o[3:0],
`endif
    /* control */
    input             id_ex_stall_i       ,
    input             time_interrupt,
    input  wire       ex_mem_stall_i      ,

    output reg        commite_o           ,
    output reg        fence_stall_o       ,
    output reg[63:0]  pc_o                ,
    output reg[31:0]  inst_o              ,
    output reg        ram_we_o            ,
    output reg[63:0]  ram_wdata_o         ,
    output reg[3:0]   mem_w_wdth_o        ,
    output reg        ram_re_o            ,
    output reg[5:0]   mem_r_wdth_o        ,
    output reg[63:0]  op1_o               ,
    output reg[63:0]  op2_o               ,
    output reg        reg_we_o            ,
    output reg[4:0]   reg_waddr_o         ,
    output reg[`ysyx_22050019_alu_len:0]alu_sel_o           ,
    output reg[63:0]  wdate_csr_reg_o     

);

  always @(posedge clk) begin
    if (rst_n) begin
        ram_we_o        <= 0;
        ram_wdata_o     <= 0;
        mem_w_wdth_o    <= 0;
        ram_re_o        <= 0;
        mem_r_wdth_o    <= 0;
        op1_o           <= 0;
        op2_o           <= 0;
        reg_we_o        <= 0;
        reg_waddr_o     <= 0;
        alu_sel_o       <= 0;
        wdate_csr_reg_o <= 0;
        fence_stall_o   <= 0;
    end
    else if ((id_ex_stall_i && (~ex_mem_stall_i))|time_interrupt) begin
        ram_we_o        <= 0;
        ram_wdata_o     <= 0;
        mem_w_wdth_o    <= 0;
        ram_re_o        <= 0;
        mem_r_wdth_o    <= 0;
        op1_o           <= 0;
        op2_o           <= 0;
        reg_we_o        <= 0;
        reg_waddr_o     <= 0;
        alu_sel_o       <= 0;
        wdate_csr_reg_o <= 0;
        fence_stall_o   <= 0;
    end
    else if (~id_ex_stall_i) begin
        ram_we_o        <= ram_we_i       ;
        ram_wdata_o     <= ram_wdata_i    ;
        mem_w_wdth_o    <= mem_w_wdth_i   ;
        ram_re_o        <= ram_re_i       ;
        mem_r_wdth_o    <= mem_r_wdth_i   ;
        op1_o           <= op1_i          ;
        op2_o           <= op2_i          ;
        reg_we_o        <= reg_we_i       ;
        reg_waddr_o     <= reg_waddr_i    ;
        alu_sel_o       <= alu_sel_i      ;
        wdate_csr_reg_o <= wdate_csr_reg_i;
        fence_stall_o   <= fence_stall_i  ;
    end
    else begin
        ram_we_o        <= ram_we_o       ;
        ram_wdata_o     <= ram_wdata_o    ;
        mem_w_wdth_o    <= mem_w_wdth_o   ;
        ram_re_o        <= ram_re_o       ;
        mem_r_wdth_o    <= mem_r_wdth_o   ;
        op1_o           <= op1_o          ;
        op2_o           <= op2_o          ;
        reg_we_o        <= reg_we_o       ;
        reg_waddr_o     <= reg_waddr_o    ;
        alu_sel_o       <= alu_sel_o      ;
        wdate_csr_reg_o <= wdate_csr_reg_o;
        fence_stall_o   <= fence_stall_o  ;
    end

  end
//======================================
`ifdef ysyx_22050019_dpic
reg [63:0] mtvec  ;
reg [63:0] mepc   ;
reg [63:0] mstatus;
reg [63:0] mcause ;
assign csr_regs_diff_o[0] = mtvec  ;
assign csr_regs_diff_o[1] = mepc   ;
assign csr_regs_diff_o[2] = mstatus;
assign csr_regs_diff_o[3] = mcause ;
`endif
//仿真信号
`ifdef ysyx_22050019_dpic

`endif

  always @(posedge clk) begin
    if (rst_n) begin
        pc_o             <= 0                ;
        inst_o           <= 0                ;
        commite_o        <= 0                ;
`ifdef ysyx_22050019_dpic
        mtvec            <= 0                ;
        mepc             <= 0                ;
        mstatus          <= 0                ;
        mcause           <= 0                ;
`endif

    end
    else if (id_ex_stall_i && (~ex_mem_stall_i)) begin
        pc_o             <= pc_i              ;
        inst_o           <= inst_i            ;
        commite_o        <= 0                 ;
`ifdef ysyx_22050019_dpic
        mtvec            <= csr_regs_diff_i[0];
        mepc             <= csr_regs_diff_i[1];
        mstatus          <= csr_regs_diff_i[2];
        mcause           <= csr_regs_diff_i[3];
`endif

    end
    else if (~id_ex_stall_i) begin
        pc_o            <= pc_i              ;
        inst_o          <= inst_i            ;
        commite_o       <= commite_i         ;
`ifdef ysyx_22050019_dpic
        mtvec           <= csr_regs_diff_i[0];
        mepc            <= csr_regs_diff_i[1];
        mstatus         <= csr_regs_diff_i[2];
        mcause          <= csr_regs_diff_i[3];
`endif

    end
    else begin
        pc_o            <= pc_o              ;
        inst_o          <= inst_o            ;
        commite_o       <= commite_o         ;
`ifdef ysyx_22050019_dpic
        mtvec           <= mtvec             ;
        mepc            <= mepc              ;
        mstatus         <= mstatus           ;
        mcause          <= mcause            ;
`endif

    end

  end


endmodule



module ysyx_22050019_IDU(
  input [63:0]   inst_addr_pc,
  input [31:0]   inst_i,
  input [63:0]   rdata1,
  input [63:0]   rdata2,

  output[63:0]   snpc,
  output         inst_j,
  output         fence_stall,

  output         ram_we,
  output[63:0]   ram_wdata,
  output         ram_re,

  output[4:0]    raddr1,
  output[4:0]    raddr2,
  output[63:0]   op1   ,
  output[63:0]   op2   ,

  output[5:0]    mem_r_wdth,
  output[3:0]    mem_w_wdth,

  output[7:0]    csr_inst_type,
  output         csr_wen,
  output[11:0]   csr_addr,
  output[4:0]    zimm,

  output         reg_we_o,
  output[4:0]    reg_waddr_o,
  output[`ysyx_22050019_alu_len:0] alu_sel

);
wire  [6:0]	opcode = inst_i[6:0]    ;
wire  [4:0]	rd     = inst_i[11:7]   ;
wire  [2:0]	funct3 = inst_i[14:12]  ;
wire  [4:0]	rs1    = inst_i[19:15]  ;
wire  [4:0]	rs2    = inst_i[24:20]  ;
wire  [6:0]	funct7 = inst_i[31:25]  ;

// 根据opcode的值分选指令类型
wire op_i       = ( opcode == `ysyx_22050019_INST_TYPE_I  )                ;//00100
wire op_b       = ( opcode == `ysyx_22050019_INST_TYPE_B  )                ;//11000
wire op_s       = ( opcode == `ysyx_22050019_INST_TYPE_S  )                ;//01000
wire op_r       = ( opcode == `ysyx_22050019_INST_TYPE_R  )                ;//01100
wire inst_l     = ( opcode == `ysyx_22050019_INST_L       )                ;//00000
wire op_csr     = ( opcode == `ysyx_22050019_INST_CSR     )                ;//11100

wire inst_addiw = ( opcode == `ysyx_22050019_INST_ADDIW   )                ;//00110
wire inst_auipc = ( opcode == `ysyx_22050019_INST_AUIPC   )                ;//00101
wire inst_lui   = ( opcode == `ysyx_22050019_INST_LUI     )                ;//01101
wire inst_jal   = ( opcode == `ysyx_22050019_INST_JAL     )                ;//11011
wire inst_jalr  = ( opcode == `ysyx_22050019_INST_JALR    )                ;//11001
wire inst_w     = ( opcode == `ysyx_22050019_INST_ADDW    )                ;//01110

// 根据funct3的值细分出
wire rv32_funct3_000    = ( funct3 == `ysyx_22050019_RV32_FUNCT3_000 )     ;
wire rv32_funct3_001    = ( funct3 == `ysyx_22050019_RV32_FUNCT3_001 )     ;
wire rv32_funct3_010    = ( funct3 == `ysyx_22050019_RV32_FUNCT3_010 )     ;
wire rv32_funct3_011    = ( funct3 == `ysyx_22050019_RV32_FUNCT3_011 )     ;
wire rv32_funct3_100    = ( funct3 == `ysyx_22050019_RV32_FUNCT3_100 )     ;
wire rv32_funct3_101    = ( funct3 == `ysyx_22050019_RV32_FUNCT3_101 )     ;
wire rv32_funct3_110    = ( funct3 == `ysyx_22050019_RV32_FUNCT3_110 )     ;
wire rv32_funct3_111    = ( funct3 == `ysyx_22050019_RV32_FUNCT3_111 )     ;
// 根据funct7的值细分出
wire rv32_funct7_000_0000 = ( funct7 == `ysyx_22050019_RV32_FUNCT7_0000000) ;
wire rv32_funct7_000_0001 = ( funct7 == `ysyx_22050019_RV32_FUNCT7_0000001) ;
wire rv32_funct7_010_0000 = ( funct7 == `ysyx_22050019_RV32_FUNCT7_0100000) ; 

//i型指令信号制作
wire  [11:0] imm_12_I = {funct7,rs2};
wire  [63:0] imm_12_I_64 = { {52{imm_12_I[11]}}, imm_12_I};
//u型指令信号制作
wire  [19:0] imm_20 = {funct7,rs2,rs1,funct3};
wire  [63:0] imm_20_U_64 = {{32{imm_20[19]}},imm_20, 12'b0}; 
//j型指令信号制作
wire  [19:0] imm_20_j = {inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21]};
wire  [63:0] imm_20_j_64 ={{43{imm_20_j[19]}},imm_20_j,1'b0};
//b型指令信号制作
wire  [11:0] imm_12_b = {inst_i[31], inst_i[7],inst_i[30:25], inst_i[11:8]};
wire  [63:0] imm_12_b_64 = {{51{imm_12_b[11]}}, imm_12_b, 1'b0};
//s型指令信号制作
wire  [11:0] imm_12_s = { inst_i[31:25], inst_i[11:7] } ;
wire  [63:0] imm_12_s_64 = { {52{imm_12_s[11]}}, imm_12_s } ;

wire  [4:0]  imm_sel ={(inst_auipc||inst_lui),(inst_jal),(op_i||inst_jalr||inst_addiw||inst_l),(op_b),(op_s)};
wire  [63:0] imm64;
ysyx_22050019_mux #( .NR_KEY(5), .KEY_LEN(5), .DATA_LEN(64)) mux_imm
(
  .key         (imm_sel), //键
  .default_out ({64{1'b0}}),
  .lut         ({		 
                 		 5'b10000,imm_20_U_64,
				             5'b01000,imm_20_j_64,
				             5'b00100,imm_12_I_64,
				             5'b00010,imm_12_b_64,
				             5'b00001,imm_12_s_64}), //键和输出的表           
  .out         (imm64)  //输出
);



//识别指令的译码模块，要注意可能多条指令间用为的方式可能会导致不兼容需要注意。
//会在每一条指令后面插入相应的行为方便调试debug以及正确性验证
//各个指令的使能信号声明（不言自明)（忽略了伪指令的部分只记录实际部分）
//=====================================================================
// 在alu中运行的指令
// 一些加法和减法指令，通过加法器接受根据指令来源的输入来实现
wire add  = op_r&&rv32_funct3_000&&rv32_funct7_000_0000;
wire addi = op_i&&rv32_funct3_000;
wire addiw= inst_addiw&&rv32_funct3_000;
wire addw = inst_w&&rv32_funct3_000&&(~rv32_funct7_000_0001)&&(~rv32_funct7_010_0000);

wire sub  = op_r&&rv32_funct3_000&&rv32_funct7_010_0000;
wire subw = inst_w&&rv32_funct3_000&&rv32_funct7_010_0000;

// 比较指令
wire slt  = op_r&&rv32_funct3_010&&rv32_funct7_000_0000;
wire slti = op_i&&rv32_funct3_010;
wire sltiu= op_i&&rv32_funct3_011;
wire sltu = op_r&&rv32_funct3_011;

// 与非异或指令的实现，通过与门或门等门电路实现
wire AND  = op_r&&rv32_funct3_111&&(~rv32_funct7_000_0001);
wire andi = op_i&&rv32_funct3_111;
wire OR   = op_r&&rv32_funct3_110&&(~rv32_funct7_000_0001);
wire ori  = op_i&&rv32_funct3_110;
wire xor0 = op_r&&rv32_funct3_100&&rv32_funct7_000_0000;
wire xori = op_i&&rv32_funct3_100;

// 逻辑左移指令，对数据进行移位
wire sll  = op_r&&rv32_funct3_001&&rv32_funct7_000_0000;
wire slli = op_i&&rv32_funct3_001&&(inst_i[31:26] == 6'b0);
wire slliw= inst_addiw&&rv32_funct3_001&&rv32_funct7_000_0000;
wire sllw = inst_w&&rv32_funct3_001;

// 逻辑右移指令，对数据进行移位
wire srl  = op_r&&rv32_funct3_101&&rv32_funct7_000_0000;//sdb测试程序menu-》小鸟游戏bug，调试定点开启diff和gtkwave，删调diff在进入页面后会报错
wire srli = op_i&&rv32_funct3_101&&(inst_i[31:26] == 6'b0);
wire srliw= inst_addiw&&rv32_funct3_101&&rv32_funct7_000_0000;
wire srlw = inst_w&&rv32_funct3_101&&rv32_funct7_000_0000;

// 算术右移指令，对数据进行移位
wire sra  = op_r&&rv32_funct3_101&&rv32_funct7_010_0000;
wire srai = op_i&&rv32_funct3_101&&(inst_i[31:26] == 6'b010000);
wire sraiw= inst_addiw&&rv32_funct3_101&&rv32_funct7_010_0000;
wire sraw = inst_w&&rv32_funct3_101&&rv32_funct7_010_0000;

// 除法指令，使用除法器进行运算
wire div  = op_r&&rv32_funct3_100&&rv32_funct7_000_0001;
wire divu = op_r&&rv32_funct3_101&&rv32_funct7_000_0001;
wire divuw= inst_w&&rv32_funct3_101&&rv32_funct7_000_0001;
wire divw = inst_w&&rv32_funct3_100&&rv32_funct7_000_0001;

// 取余指令，使用取余器进行运算（除法器）
wire rem  = op_r&&rv32_funct3_110&&rv32_funct7_000_0001;
wire remu = op_r&&rv32_funct3_111&&rv32_funct7_000_0001;
wire remuw= inst_w&&rv32_funct3_111&&rv32_funct7_000_0001;
wire remw = inst_w&&rv32_funct3_110&&rv32_funct7_000_0001;

// 乘法指令，使用乘法器进行运算
wire mul   = op_r&&rv32_funct3_000&&rv32_funct7_000_0001;
wire mulh  = op_r&&rv32_funct3_001&&rv32_funct7_000_0001;
wire mulhsu= op_r&&rv32_funct3_010&&rv32_funct7_000_0001;
wire mulhu = op_r&&rv32_funct3_011&&rv32_funct7_000_0001;
wire mulw  = inst_w&&rv32_funct3_000&&rv32_funct7_000_0001;
// 加载指令，从内存中获取相应的数据
wire lb   = inst_l&&rv32_funct3_000;
wire lbu  = inst_l&&rv32_funct3_100;
/* verilator lint_off UNUSED */wire ld   = inst_l&&rv32_funct3_011;//读双字就已经默认了全读，exu在default中个设定控制,方便调试用的
wire lh   = inst_l&&rv32_funct3_001;
wire lhu  = inst_l&&rv32_funct3_101;
wire lw   = inst_l&&rv32_funct3_010;
wire lwu  = inst_l&&rv32_funct3_110;

// 存储指令，向内存中写入相应的数据
wire sb   = op_s&&rv32_funct3_000;
wire sd   = op_s&&rv32_funct3_011;
wire sh   = op_s&&rv32_funct3_001;
wire sw   = op_s&&rv32_funct3_010;

// 一些不经过alu运行的跳转指令
// 分支跳转指令，这一部分在idu中进行跳转在idu阶段就可以输出跳转信号
wire beq  = op_b&&rv32_funct3_000;
wire bge  = op_b&&rv32_funct3_101;
wire bgeu = op_b&&rv32_funct3_111;
wire blt  = op_b&&rv32_funct3_100;
wire bltu = op_b&&rv32_funct3_110;
wire bne  = op_b&&rv32_funct3_001;
/*******************************csr指令的控制处理**************************/
wire csrrw = op_csr&&rv32_funct3_001;// csr写入x[rd]，x[rs1]写入csr
wire csrrs = op_csr&&rv32_funct3_010;// 读csr和x[rs1]按位或结果再写回csr，原本csr值写回x[rd]
wire csrrc = op_csr&&rv32_funct3_011;// 读csr和x[rs1]按位与结果再写回csr，原本csr值写回x[rd]
wire csrrwi= op_csr&&rv32_funct3_101;// csr写入x[rd]，zimm写入csr
wire csrrsi= op_csr&&rv32_funct3_110;// csr写入x[rd]，zimm|csr和x写入csr
wire csrrci= op_csr&&rv32_funct3_111;// csr写入x[rd]，zimm&csr和x写入csr
wire ecall = op_csr&&(inst_i[31:7] == 25'b0);//snpc->mtvec,把当前pc保存给mepc，把异常号0xb给mcause
wire mret  = inst_i[31:0] == 32'b0011000_00010_00000_000_00000_1110011;//处理mstatus，跳转回发生异常时的地址

//csr控制信号生成
assign csr_inst_type = {csrrci,csrrsi,csrrwi,csrrc,mret,csrrs,ecall,csrrw};
assign csr_wen       = csrrw||ecall||csrrs||csrrc||csrrwi||csrrsi||csrrci;
assign csr_addr      = csr_wen ? imm_12_I : 12'b0;
assign zimm          = rs1;

// fence 一致性
wire fencei = inst_i[31:0] == 32'b0000000_00000_00000_001_00000_0001111;
assign fence_stall = fencei;
//***********************************************************************
//这里的控制模块把输出位宽的控制集成到了单根线中，在alu中根据控制信号线来分辨相应的正确输出
//***********************************************************************
// 带i的是立即数操作在选择,带w的是字操作，带u的是无符号数，对于算术移位乘法除法取余不带u需要考虑符号，加法采用的补码加所以可以忽略
// alu部分制作
// =====================
// 使用加法器的控制信号划分
wire alu_add    = add||addi||inst_auipc||inst_lui||inst_jal||inst_jalr||op_s||inst_l;
wire alu_add_32 = addiw||addw;
// 减法
wire alu_sub    = sub;
wire alu_sub_32 = subw;
// 比较
wire alu_slt    = slt||slti;
wire alu_sltu   = sltiu||sltu;
// =====================
// 对操作数进行与或等操作的控制信号划分
wire alu_and    = andi||AND;
wire alu_or     = OR||ori;
wire alu_xor    = xori||xor0;
// =====================
// 一些alu移位指令控制信号
// =====================
// 逻辑左移
wire alu_sll_64 = sll;
wire alu_slli_64= slli;
wire alu_slli_32= slliw;
wire alu_sll_32 = sllw;
// 逻辑右移
wire alu_srl_64 = srl;
wire alu_srli_64= srli;
wire alu_srli_32= srliw;
wire alu_srl_32 = srlw;
// 算术右移
wire alu_sra_64 = sra;
wire alu_srai_64= srai;
wire alu_srai_32= sraiw;
wire alu_sra_32 = sraw;
// =====================
// 一些alu除法器指令控制信号
// =====================

// =====================
// 一些alu乘法器指令控制信号
// =====================

assign alu_sel  =  {mulw,mulhu,mulhsu,mulh,mul,div,divu,divuw,divw,rem,remu,remuw,remw,alu_sra_32,alu_srai_32,alu_srai_64,alu_sra_64,alu_srl_32,alu_srli_32,alu_srli_64,alu_srl_64,alu_sll_32,alu_slli_32,alu_slli_64,alu_sll_64,alu_xor,alu_or,alu_and,alu_sltu,alu_slt,alu_sub_32,alu_sub,alu_add_32,alu_add};


//=====================================================================
/*
SLLIW、SRLIW、SRAIW是RV64I仅有的指令，与其定义相类似，但是它们对32位数值进
行操作，并产生有符号的32位结果。如果imm[5]≠0，SLLIW、SRLIW、SRAIW指令将会产生
一个异常。
对于这一个问题采用的解决方法是指令译码时强制imm[5]=0,但在一些关键的控制信号中使用inst_w可能会导致无效指令被更新出错误的值，
我的解决措施是将写使能inst_w拆分为对应的有效指令，这可以让无效指令无法写入reg。
*/
//=====================================================================
//对于reg和mem的控制信号的信号配置处理
//reg_control
assign reg_we_o    =  op_i||inst_auipc||inst_lui||inst_jal||inst_jalr||op_r||(addiw|slliw|sraiw|srliw)||(inst_w)||(csrrw||csrrs||csrrc||csrrwi||csrrsi|csrrci);//使能
assign reg_waddr_o =  reg_we_o|inst_l ? rd : 5'b0;
assign raddr1      =  (op_i||inst_jalr||op_s||op_r||inst_l||inst_addiw||(inst_w)||op_b)||(csrrw||csrrs||csrrc||csrrwi||csrrsi||csrrci)?rs1:5'b0;//数据
assign raddr2      =  (op_b||op_s||op_r||(inst_w))?rs2:5'b0;

//mem_control
assign ram_we      = op_s;
assign ram_wdata   = op_s ? rdata2 : 64'b0;//write
assign ram_re      = inst_l;
//mem_r_wdth
assign mem_r_wdth = {lw,lh,lb,lwu,lhu,lbu};               //of32,16,8  || 32,16,8   
//mem_w_wdth
assign mem_w_wdth = {sd,sb,sh,sw};                        //else(64)---8---16---32--


//=====================================================================
//操作数op1/op2的通过指令类型来选择处理
//op1_sel
wire [1:0]op1_en   = {(inst_auipc||inst_jal||inst_jalr) ,(op_i||op_s||op_r||inst_addiw||inst_l||(inst_w))};
ysyx_22050019_mux #( .NR_KEY(2), .KEY_LEN(2), .DATA_LEN(64) ) mux_op1
(
  .key         (op1_en), //键
  .default_out (64'b0),
  .lut         ({2'b10,inst_addr_pc,
                 2'b01,rdata1
                 }), //键和输出的表           
  .out         (op1)  //输出
);

//op2_sel
wire [2:0]op2_en   =  {(op_i||inst_auipc||inst_lui||op_s||inst_addiw||inst_l) ,op_r||(inst_w),(inst_jal||inst_jalr)};
ysyx_22050019_mux #( .NR_KEY(3), .KEY_LEN(3), .DATA_LEN(64)) mux_op2
(
  .key         (op2_en), //键
  .default_out (64'b0),
  .lut         ({
                 3'b100,imm64,
                 3'b010,rdata2,
                 3'b001,64'd4}),         
  .out         (op2)  //输出
);


//=====================================================================
wire [63:0]b_ab_s  ;
wire beq_y         ; 
wire b_ab_1_s       ;
wire b_ab_1_u;
//对于要进行pc跳转的指令信号进行控制
//pc_branch
assign inst_j      = inst_jal||inst_jalr||beq&&beq_y||bne&&(~beq_y)||bge&&(~b_ab_1_s)||blt&&b_ab_1_s||bltu&&b_ab_1_u||bgeu&&(~b_ab_1_u)||(ecall||mret); //跳转信号制作处
wire [1:0]branch   = {(inst_jal||op_b),inst_jalr};
wire [63:0]flush_result1 = inst_addr_pc+imm64;
wire [63:0]flush_result2 = (rdata1+imm_12_I_64)&(~64'b1);
ysyx_22050019_mux #( .NR_KEY(2), .KEY_LEN(2), .DATA_LEN(64)) mux_branch
(
  .key         (branch), //键
  .default_out (64'd0),
  .lut         ({2'b10,flush_result1,
                 2'b01,flush_result2
                 }),           
  .out         (snpc)  //输出
);


//=====================================================================
//b型指令结果处理
assign b_ab_s  = rdata1 + (~rdata2 + 64'b1);//补码-法，进行判断运算
assign beq_y             = b_ab_s == 64'b0;                  //ab->equal
assign b_ab_1_s       = ( ( ( rdata1[63] == 1'b1 ) && ( rdata2[63] == 1'b0 ) ) 
                        | ( (rdata1[63] == rdata2[63] ) && ( b_ab_s[63] == 1'b1 ) ) );//有符号小于<
assign b_ab_1_u      = ( ( ( rdata1[63] == 1'b0 ) && ( rdata2[63] == 1'b1 ) ) 
                        | ( (rdata1[63] == rdata2[63] ) && ( b_ab_s[63] == 1'b1 ) ) );//无符号小于<

endmodule

module ysyx_22050019_IF_ID (
    input     clk                 ,
    input     rst_n               ,
    input     [63:0] pc_i         ,
    input     [31:0] inst_i       ,

    /* valid */
    input            commite_i    ,
    output reg       commite_o    ,

    /* control */
    input            if_id_stall_i,
    input            id_ex_stall_i,
    input            id_j_flush,

    output reg[63:0] pc_o         ,
    output reg[31:0] inst_o 
);
//跳转的时刻ifu是不能向下发送commite的确认的，跳转后需要重新取一条对应指令的数据，因为暂停期间跳转送进来的地址只有在结束时刻才能确认是对的。
// 对于跳转进行了两个保险，其实现在来看ifu哪一个就够了，主要起作用的是在ifu，跳转后会进行一个nop操作，把这个commite_i的输出反压位0作为nop吧
//id阶段暂停时如果是跳转指令，在跳转同时把上一级别寄存器状态刷新了，否则一直跳转阻塞
//中断的跳转只会维持一个周期，那么记录当前ifu的同时，计时器中断跳转需要强制更新if_id的信息为nop，同时告诉ifu，buffer，取中断跳转的pc
  always @(posedge clk) begin
    if (rst_n) begin
        pc_o     <= 0;
        inst_o   <= 0;
        commite_o<= 0;
    end
    else if (~if_id_stall_i && id_j_flush) begin
        pc_o     <= pc_i;
        inst_o   <= 0;
        commite_o<= 0;
    end
    else if (~if_id_stall_i) begin
        pc_o     <= pc_i     ;
        inst_o   <= commite_i ? inst_i : 0;
        commite_o<= commite_i;
    end
    else begin
        pc_o     <= pc_o     ;
        inst_o   <= inst_o   ;
        commite_o<= commite_o;
    end

  end
endmodule
//第一级流水，时序逻辑

module ysyx_22050019_IFU
(
    input                 clk               ,
    input                 rst_n             ,

    //pc 的跳转控制信号
    input                 inst_j            ,
    input   [31:0]        snpc              ,  
    
    input  [31:0]         inst_i            ,
    input                 inst_valid_i      ,
  
    output                inst_commite      ,

    //五级流水的适配控制信号的输入和输出
    input                 pc_stall_i        ,
    
    // 送出指令和对于pc的接口（打了一拍）
    output  [31:0]        inst_addr_o       , //到指令寄存器中取指令的地址
    output  [31:0]        inst_o
);
`ifdef ysyx_22050019_dpic
  localparam RESET_VAL = 32'h8000_0000;
`else
  localparam RESET_VAL = 32'h3000_0000;
`endif
//=========================
// pc计数器逻辑
  wire pc_wen = inst_valid_i && (~pc_stall_i); //暂停指示信号，目前用这个代替，后面需要参考优秀设计
  reg [31:0]     inst_addr; 
// pc 计数器
always @ (posedge clk) begin
    // 复位
    if (rst_n) begin
        inst_addr <= RESET_VAL;
    // 跳转
    end else if (inst_j&(~pc_stall_i)) begin
        inst_addr <= snpc;
    // 暂停
    end else if (~pc_wen) begin
        inst_addr <= inst_addr;
    // 地址加4
    end else begin
        inst_addr <= inst_addr + 32'h4;
    end
end
//=========================
//IFU第一级取指令流水操作
assign inst_addr_o = inst_j&(~pc_stall_i) ? snpc : inst_addr;
assign inst_o      = inst_commite ? inst_i[31:0] :0;
assign inst_commite= pc_wen & ~inst_j;
endmodule
// 目前写的aw_valid信号是用ram写使能暂时代替，这意味着无法持续，当写请求需要等待时，需要修改这里的逻辑
module ysyx_22050019_LSU# (
    parameter AXI_DATA_WIDTH    = 64,
    parameter AXI_ADDR_WIDTH    = 64
)(
  input               clk            ,
  input               rst            ,
  // 读写位宽
  input [5:0]         mem_r_wdth     ,
  input [3:0]         mem_w_wdth     ,

  // 读写数据
  input [63:0]        ram_wdata_i    ,
  input               ram_we_i       ,

  input               ram_re_i       ,
  
  // alu 结果
  input [63:0]        result,
  input  [4:0]        waddr_reg_i    ,
  // 向reg的写数据
  output              wen_reg_o      ,
  output     [4:0]    waddr_reg_o    ,
  output     [63:0]   wdata_reg_o    ,

  // 分为读写两个通道描述信号
  // 写通道

  output     [31:0]   ram_waddr      ,
  input               m_axi_aw_ready ,
  output              m_axi_aw_valid ,

  output reg [63:0]   ram_wdata      ,
  output reg [7:0]    wmask          ,
  input               m_axi_w_ready  ,
  output reg          m_axi_w_valid  ,

  input [1:0]         ram_wresp_i    ,
  output reg          m_axi_b_ready  ,
  input               m_axi_b_valid  ,

  /* control */
  output              lsu_stall_req  ,

  // 读通道

  input [63:0]        ram_rdata_i    ,
  input [1:0]         m_axi_r_resp   ,
  output reg          m_axi_r_ready  ,
  input               m_axi_r_valid  ,

  input               m_axi_ar_ready ,
  output              m_axi_ar_valid ,
  output  [31:0]      ram_raddr   

);
//==========================信号初始化==============================
localparam RS_IDLE = 2'd1;
localparam RS_RHS  = 2'd2;

localparam WS_IDLE = 2'd1;
localparam WS_WHS  = 2'd2;
localparam WS_BHS  = 2'd3;

reg[1:0] rstate;
reg[1:0] next_rstate;

reg [1:0] rresp;
reg [4:0] waddr_reg;
reg [5:0] axi_m_mem_r_wdth;

reg[1:0] wstate;
reg[1:0] next_wstate;

reg [1:0] wresp;
//mem_r_data_mux
//ram的读地址发送端信号控制
reg ar_valid;
reg [31:0] ar_addr ;
wire [63:0] mem_r_data;
wire [31:0] strb_rdata = ram_raddr[2] ? ram_rdata_i[63:32] >> {ar_addr[1:0],3'b0}: ram_rdata_i[31:0] >> {ar_addr[1:0],3'b0};
ysyx_22050019_mux #( .NR_KEY(6), .KEY_LEN(6), .DATA_LEN(64)) mem_r_data_mux          //of32,16,8  || 32,16,8
(
  .key         (axi_m_mem_r_wdth),
  .default_out (ram_rdata_i),
  .lut         ({		 6'b100000,{{32{strb_rdata[31]}},strb_rdata[31:0]} ,
                 		 6'b010000,{{48{strb_rdata[15]}},strb_rdata[15:0]} ,
				             6'b001000,{{56{strb_rdata[7 ]}},strb_rdata[7 :0]} ,
				             6'b000100,{32'b0,strb_rdata[31:0]}                 ,
				             6'b000010,{48'b0,strb_rdata[15:0]}                 ,
				             6'b000001,{56'b0,strb_rdata[7 :0]}                 
                    }),        
  .out         (mem_r_data)  
);

//mem_w_wdth_mux
wire [7:0] mem_w_mask;
wire [63:0]strb_wdata = result[2] ? {ram_wdata_i[31: 0],ram_wdata_i[63:32]} << {result[1:0],3'b0} : ram_wdata_i[63:0] << {result[1:0],3'b0} ;
ysyx_22050019_mux #( .NR_KEY(4), .KEY_LEN(4), .DATA_LEN(8)) mem_w_wdth_mux             //basic-64---8---16---32--
(
  .key         (mem_w_wdth),
  .default_out (8'b11111111),
  .lut         ({		 4'b1000,8'b11111111,
                     4'b0100,result[2] ? 8'b00010000 << result[1:0] : 8'b00000001 << result[1:0],
                 		 4'b0010,result[2] ? 8'b00110000 << result[1:0] : 8'b00000011 << result[1:0],
				             4'b0001,result[2] ? 8'b11110000 << result[1:0] : 8'b00001111 << result[1:0]
                    }),        
  .out         (mem_w_mask)  
);

//=============================================================
//==========================写通道==============================



    //// ------------------State Machine------------------////
    
    // 写通道状态切换
reg aw_wait; 
always@(posedge clk)begin
  if(rst) wstate <= WS_IDLE;
  else    wstate <= next_wstate;
end

always@(*) begin
  if(rst) next_wstate = WS_IDLE;
  else case(wstate)
    WS_IDLE :if(m_axi_aw_valid && m_axi_aw_ready) next_wstate = WS_WHS;
      else next_wstate = WS_IDLE;

    WS_WHS : if(m_axi_w_ready && m_axi_w_valid)   next_wstate = WS_BHS;
      else next_wstate = WS_WHS;

    WS_BHS : if(m_axi_b_valid)   next_wstate = WS_IDLE;
      else next_wstate = WS_BHS;

    default : next_wstate = RS_IDLE;
  endcase
end

always@(posedge clk)begin
  if(rst)begin
    m_axi_w_valid  <= 1'b0;
    m_axi_b_ready  <= 1'b0;
    wresp          <= 2'b0;
    aw_wait         <= 0;
    
  end
  else begin
    case(wstate)
      WS_IDLE:
      if(next_wstate==WS_WHS)begin
        m_axi_w_valid  <= 1'b1;
      end
      else begin
        m_axi_w_valid  <= 1'b0;
      end

      WS_WHS:if(next_wstate==WS_BHS)begin
        m_axi_w_valid  <= 1'b0;
        m_axi_b_ready  <= 1'b1;
      end
      
      WS_BHS:if(next_wstate==WS_IDLE)begin
        m_axi_b_ready  <= 1'b0;
      end
      default:begin
      end
    endcase
  end
end

reg [31:0] aw_addr ;
always@(posedge clk) begin
  if(rst) begin
    aw_addr <= 0;
    ram_wdata<=0;
    wmask <= 8'b0;
  end
  else if(ram_we_i)begin
    aw_addr <= result[31:0];
    ram_wdata<=strb_wdata;
    wmask <= mem_w_mask;
  end
  else if (m_axi_b_valid&&m_axi_b_ready)begin
    aw_addr <= 0;
    ram_wdata<=0;
    wmask <= 8'b0;
  end
end

//ram的写地址发送端信号控制
reg aw_valid;
always@(posedge clk) begin
  if(rst) 
    aw_valid <= 1'b0;
  else if (m_axi_aw_ready&&m_axi_aw_valid)
    aw_valid <= 1'b0;
  else if(ram_we_i)
    aw_valid <= 1'b1;
  else aw_valid <= aw_valid;
end

assign ram_waddr      = aw_addr;
assign m_axi_aw_valid = aw_valid;

//=============================================================
//==========================读通道==============================

    //// ------------------State Machine------------------////
    // 读通道状态切换

always@(posedge clk)begin
  if(rst) rstate <= RS_IDLE;
  else rstate <= next_rstate;
end

always@(*) begin
  if(rst) next_rstate = RS_IDLE;
  else case(rstate)
    RS_IDLE :if(m_axi_ar_ready&&m_axi_ar_valid) begin
             next_rstate = RS_RHS;
    end
      else next_rstate = RS_IDLE;

    RS_RHS : if(m_axi_r_valid)next_rstate = RS_IDLE;
    else next_rstate = RS_RHS;

    default : next_rstate = RS_IDLE;
  endcase
end

// 握手信号状态机
always@(posedge clk)begin
  if(rst)begin
    rresp           <= 2'b0;
    m_axi_r_ready   <= 1'b0;
  end
  else begin
    case(rstate)
      RS_IDLE:
      if(next_rstate==RS_RHS) begin
        m_axi_r_ready    <= 1'b1;
      end
      else begin
        rresp            <= 2'b0;
        m_axi_r_ready    <= 1'b0;

      end

      RS_RHS:if(next_rstate==RS_IDLE)begin
        m_axi_r_ready    <= 1'b0;
        rresp            <= m_axi_r_resp;
      end
      else begin

        m_axi_r_ready <= 1'b1;
      end
      default:begin
      end
    endcase
  end
end

// 寄存器写使能控制
always@(posedge clk) begin
  if(rst) 
    waddr_reg     <= 5'b0;
  else if(ram_re_i)
        waddr_reg        <= waddr_reg_i;
  else if (m_axi_r_valid)
        waddr_reg        <= 5'b0;
  else 
    waddr_reg     <= waddr_reg;
end

always@(posedge clk) begin
  if(rst) 
    axi_m_mem_r_wdth <= 6'b0;
  else if(ram_re_i)
        axi_m_mem_r_wdth <= mem_r_wdth;
  else if (m_axi_r_valid)
        axi_m_mem_r_wdth <= 6'b0;
  else 
    axi_m_mem_r_wdth <= axi_m_mem_r_wdth;
end

//reg_control
assign wen_reg_o    = m_axi_r_valid;
assign waddr_reg_o  = m_axi_r_valid ? waddr_reg : 5'b0;
assign wdata_reg_o  = m_axi_r_valid ? mem_r_data : 64'b0;

always@(posedge clk) begin
  if(rst) 
    ar_valid <= 1'b0;
  else if (m_axi_ar_ready&&m_axi_ar_valid)
    ar_valid <= 1'b0;
  else if(ram_re_i)
    ar_valid <= 1'b1;
  else ar_valid <= ar_valid;
end

always@(posedge clk) begin
  if(rst) 
    ar_addr <= 0;
  else if(ram_re_i)
    ar_addr <= result[31:0];
  else if (m_axi_r_ready&&m_axi_r_valid)
    ar_addr <= 0;
  else ar_addr <= ar_addr;
end

assign ram_raddr      = ar_addr;
assign m_axi_ar_valid = ar_valid;

//流水线control
//在流水段暂停时，如果下方模块不暂停，会清空该流水段寄存器的数据，这会让流水段寄存器不在发出重复数据请求，但同时，这也会丢失
assign lsu_stall_req = (ram_we_i | m_axi_aw_valid||m_axi_w_valid || m_axi_b_ready || next_wstate != WS_IDLE)||(ram_re_i | m_axi_ar_valid | next_rstate == RS_RHS);
//=============================================================
endmodule


module ysyx_22050019_MEM_WB (
    input            clk                 ,
    input            rst_n               ,
    input     [63:0] pc_i                ,
    input     [31:0] inst_i              ,
    input            reg_we_wbu_i        ,
    input     [4:0]  reg_waddr_wbu_i     ,
    input     [63:0] reg_wdata_wbu_i     ,
`ifdef ysyx_22050019_dpic
    input     [63:0] csr_regs_diff_i[3:0],
    output    [63:0] csr_regs_diff_o[3:0],
`endif

    input            commite_i           ,

    /* control */
    input            mem_wb_stall_i      ,

    output reg       commite_o           ,
    output reg[63:0] pc_o                ,
    output reg[31:0] inst_o              ,
    output reg       reg_we_wbu_o        ,
    output reg[4:0]  reg_waddr_wbu_o     ,
    output reg[63:0] reg_wdata_wbu_o     

);

  always @(posedge clk) begin
    if(rst_n) begin
        reg_we_wbu_o         <= 0;
        reg_waddr_wbu_o      <= 0;
        reg_wdata_wbu_o      <= 0;
    end
    else if(~mem_wb_stall_i)begin
        reg_we_wbu_o         <= reg_we_wbu_i ;
        reg_waddr_wbu_o      <= reg_waddr_wbu_i;
        reg_wdata_wbu_o      <= reg_wdata_wbu_i;
    end

  end

//仿真信号
`ifdef ysyx_22050019_dpic
reg [63:0] mtvec  ;
reg [63:0] mepc   ;
reg [63:0] mstatus;
reg [63:0] mcause ;
assign csr_regs_diff_o[0] = mtvec  ;
assign csr_regs_diff_o[1] = mepc   ;
assign csr_regs_diff_o[2] = mstatus;
assign csr_regs_diff_o[3] = mcause ;
import "DPI-C" function void difftest_valid();
import "DPI-C" function void ebreak();
always@(posedge clk)begin
  if(commite_o) difftest_valid();
end
//=====================================================================
//inst，设置了捕捉没实现的csr指令
always @(*) begin
  if (inst_i == 32'h100073) begin
    $display("pc %x",pc_i);
    ebreak();
  end
end

`endif
`ifdef ysyx_22050019_dpic

`endif
  always @(posedge clk) begin
    if (rst_n) begin
        pc_o             <= 0;
        inst_o           <= 0;
        commite_o        <= 0;
`ifdef ysyx_22050019_dpic
        mtvec            <= 0;
        mepc             <= 0;
        mstatus          <= 0;
        mcause           <= 0;
`endif

    end
    else if (~mem_wb_stall_i) begin
        pc_o            <= pc_i           ;
        inst_o          <= inst_i         ;
        commite_o       <= commite_i      ;
`ifdef ysyx_22050019_dpic
        mtvec           <= csr_regs_diff_i[0];
        mepc            <= csr_regs_diff_i[1];
        mstatus         <= csr_regs_diff_i[2];
        mcause          <= csr_regs_diff_i[3];
`endif

    end
    else begin
        pc_o            <= pc_o     ;
        inst_o          <= inst_o   ;
        commite_o       <= 0        ;
`ifdef ysyx_22050019_dpic
        mtvec           <= mtvec    ;
        mepc            <= mepc     ;
        mstatus         <= mstatus  ;
        mcause          <= mcause   ;
`endif

    end

  end




endmodule

module ysyx_22050019_pipeline_Control (

  input              lsu_stall_req  ,
  input              alu_stall_req  ,
  input              stall_raw_req ,

  output wire        pc_stall_o     ,
  output wire        if_id_stall_o  ,
  output wire        id_ex_stall_o  ,
  output wire        ex_mem_stall_o ,
  output wire        mem_wb_stall_o
);

  /* 
   * stall-保持流水线寄存器的值不随时钟而刷新，完成流水线的暂停
   */

  assign pc_stall_o     = if_id_stall_o;
  assign if_id_stall_o  = id_ex_stall_o;
  assign id_ex_stall_o  = ex_mem_stall_o | alu_stall_req | stall_raw_req;
  assign ex_mem_stall_o = mem_wb_stall_o | lsu_stall_req;
  assign mem_wb_stall_o = 0;

endmodule
// 控制写回reg的数据,这里放到lsu后面主要是考虑给处理冒险单元那方便判断遗漏的没有写的数据
// 这样可以全覆盖五级流水两周期读一条指令时出现的exu需要前递的数据，可以在lsu阶段补上。
module ysyx_22050019_WBU(
    input            reg_we_exu_lsu_i    ,
    input            reg_we_lsu_i        ,
    input     [4:0]  reg_waddr_exu_i     ,
    input     [4:0]  reg_waddr_lsu_i     ,
    input     [63:0] reg_wdata_lsu_i     ,
    input     [63:0] reg_wdata_csr_i     ,
    input     [63:0] reg_wdata_exu_i     ,

    output reg       reg_we_wbu_o        ,
    output reg[4:0]  reg_waddr_wbu_o     ,
    output reg[63:0] reg_wdata_wbu_o     
);
assign reg_we_wbu_o         = reg_we_exu_lsu_i|reg_we_lsu_i  ;
assign reg_waddr_wbu_o      = reg_waddr_exu_i|reg_waddr_lsu_i;
assign reg_wdata_wbu_o      = reg_we_lsu_i ? (reg_we_lsu_i ? reg_wdata_lsu_i : 64'b00) : (reg_wdata_exu_i|reg_wdata_csr_i);
endmodule

module ysyx_22050019_regs(
  input     clk,
  input     rst_n,
  input     [64-1:0] now_pc,
  input     [64-1:0] wdata  ,
  input     [5-1:0] waddr  ,
  input     wen                     ,
`ifdef ysyx_22050019_dpic
  input     [64-1:0] csr_regs_diff[3:0],
`endif


  input     [5-1:0] raddr1 ,
  input     [5-1:0] raddr2 ,
  output    [64-1:0] rdata1 ,
  output    [64-1:0] rdata2
);
  reg [64-1:0] regs [31:0];
integer i;
//写寄存器
  always @(posedge clk) begin
    if(rst_n)begin
    for (i = 0; i < 32; i=i+1) begin
      regs[i] <= 0;
    end
    end
    else if (wen && waddr!= 5'b0) begin 
      regs[waddr] <= wdata;
    end
  end
//=========================

   //在这里实现了流水冲突中先写后读的冲突问题
  assign rdata1 = regs[raddr1] ;
  assign rdata2 = regs[raddr2] ;

//=========================
/*
  assign    rdata1 = (raddr1 == 5'b0) ? 64'b0 : regs[raddr1] ;
  assign    rdata2 = (raddr2 == 5'b0) ? 64'b0 : regs[raddr2] ;
*/

`ifdef ysyx_22050019_dpic
import "DPI-C" function void get_regs(input logic [63:0] a []);
  wire [64-1:0] regs1 [36:0];
 
  assign regs1[36:33] = csr_regs_diff [3:0];
  assign regs1[32]    = now_pc;
  assign regs1[31:0]  = regs [31:0];
  initial get_regs(regs1);  // regs1为通用寄存器的二维数组变量
`endif

endmodule


module ysyx_22050019(
  input       clock,
  input       reset,
  input           io_interrupt      ,
  input           io_master_awready ,    
  output          io_master_awvalid ,    
  output [3:0]    io_master_awid    ,  
  output [31:0]   io_master_awaddr  ,    
  output [7:0]    io_master_awlen   ,  
  output [2:0]    io_master_awsize  ,    
  output [1:0]    io_master_awburst ,    
  input           io_master_wready  ,    
  output          io_master_wvalid  ,    
  output [63:0]   io_master_wdata   ,  
  output [7:0]    io_master_wstrb   ,  
  output          io_master_wlast   ,  
  output          io_master_bready  ,    
  input           io_master_bvalid  ,    
  input [3:0]     io_master_bid     ,
  input [1:0]     io_master_bresp   ,  
  input           io_master_arready ,    
  output          io_master_arvalid ,    
  output [3:0]    io_master_arid    ,  
  output [31:0]   io_master_araddr  ,    
  output [7:0]    io_master_arlen   ,  
  output [2:0]    io_master_arsize  ,    
  output [1:0]    io_master_arburst ,    
  output          io_master_rready  ,    
  input           io_master_rvalid  ,    
  input [3:0]     io_master_rid     ,
  input [1:0]     io_master_rresp   ,  
  input [63:0]    io_master_rdata   ,  
  input           io_master_rlast   ,
  output          io_slave_awready  ,    
  input           io_slave_awvalid  ,    
  input [3:0]     io_slave_awid     ,
  input [31:0]    io_slave_awaddr   ,  
  input [7:0]     io_slave_awlen    ,  
  input [2:0]     io_slave_awsize   ,  
  input [1:0]     io_slave_awburst  ,    
  output          io_slave_wready   ,  
  input           io_slave_wvalid   ,  
  input [63:0]    io_slave_wdata    ,  
  input [7:0]     io_slave_wstrb    ,  
  input           io_slave_wlast    ,  
  input           io_slave_bready   ,  
  output          io_slave_bvalid   ,  
  output [3:0]    io_slave_bid      ,
  output [1:0]    io_slave_bresp    ,  
  output          io_slave_arready  ,    
  input           io_slave_arvalid  ,    
  input [3:0]     io_slave_arid     ,
  input [31:0]    io_slave_araddr   ,  
  input [7:0]     io_slave_arlen    ,  
  input [2:0]     io_slave_arsize   ,  
  input [1:0]     io_slave_arburst  ,    
  input           io_slave_rready   ,  
  output          io_slave_rvalid   ,  
  output [3:0]    io_slave_rid      ,
  output [1:0]    io_slave_rresp    ,  
  output [63:0]   io_slave_rdata    ,  
  output          io_slave_rlast    ,  
  output [5:0]    io_sram0_addr     ,
  output          io_sram0_cen      ,
  output          io_sram0_wen      ,
  output [127:0]  io_sram0_wmask    ,  
  output [127:0]  io_sram0_wdata    ,  
  input  [127:0]  io_sram0_rdata    ,  
  output [5:0]    io_sram1_addr     ,
  output          io_sram1_cen      ,
  output          io_sram1_wen      ,
  output [127:0]  io_sram1_wmask    ,  
  output [127:0]  io_sram1_wdata    ,  
  input  [127:0]  io_sram1_rdata    ,
  output [5:0]    io_sram2_addr     ,
  output          io_sram2_cen      ,
  output          io_sram2_wen      ,
  output [127:0]  io_sram2_wmask    ,  
  output [127:0]  io_sram2_wdata    ,  
  input  [127:0]  io_sram2_rdata    ,  
  output [5:0]    io_sram3_addr     ,
  output          io_sram3_cen      ,
  output          io_sram3_wen      ,
  output [127:0]  io_sram3_wmask    ,  
  output [127:0]  io_sram3_wdata    ,  
  input  [127:0]  io_sram3_rdata    ,

  output [5:0]    io_sram4_addr     ,
  output          io_sram4_cen      ,
  output          io_sram4_wen      ,
  output [127:0]  io_sram4_wmask    ,  
  output [127:0]  io_sram4_wdata    ,  
  input  [127:0]  io_sram4_rdata    ,  
  output [5:0]    io_sram5_addr     ,
  output          io_sram5_cen      ,
  output          io_sram5_wen      ,
  output [127:0]  io_sram5_wmask    ,  
  output [127:0]  io_sram5_wdata    ,  
  input  [127:0]  io_sram5_rdata    ,  
  output [5:0]    io_sram6_addr     ,
  output          io_sram6_cen      ,
  output          io_sram6_wen      ,
  output [127:0]  io_sram6_wmask    ,  
  output [127:0]  io_sram6_wdata    ,  
  input  [127:0]  io_sram6_rdata    ,  
  output [5:0]    io_sram7_addr     ,
  output          io_sram7_cen      ,
  output          io_sram7_wen      ,
  output [127:0]  io_sram7_wmask    ,  
  output [127:0]  io_sram7_wdata    ,  
  input  [127:0]  io_sram7_rdata     
);
//取出指令的逻辑分离出来
wire[63:0]pc  ;
wire[31:0]inst;

//不需要的接口
assign  io_slave_awready =0;    
assign  io_slave_wready  =0;  
assign  io_slave_bvalid  =0;  
assign  io_slave_bid     =0;
assign  io_slave_bresp   =0;  
assign  io_slave_arready =0;    
assign  io_slave_rvalid  =0;  
assign  io_slave_rid     =0;
assign  io_slave_rresp   =0;  
assign  io_slave_rdata   =0;  
assign  io_slave_rlast   =0;  
assign  io_sram4_addr    =0;
assign  io_sram4_cen     =0;
assign  io_sram4_wen     =0;
assign  io_sram4_wmask   =0;
assign  io_sram4_wdata   =0;
assign  io_sram5_addr    =0;
assign  io_sram5_cen     =0;
assign  io_sram5_wen     =0;
assign  io_sram5_wmask   =0;
assign  io_sram5_wdata   =0;
assign  io_sram6_addr    =0;
assign  io_sram6_cen     =0;
assign  io_sram6_wen     =0;
assign  io_sram6_wmask   =0;
assign  io_sram6_wdata   =0;
assign  io_sram7_addr    =0;
assign  io_sram7_cen     =0;
assign  io_sram7_wen     =0;
assign  io_sram7_wmask   =0;
assign  io_sram7_wdata   =0;
// 虚拟sram_axi握手模拟

wire ifu_commite;
wire [63:0]pc_ifu;

wire [31:0]inst_ifu;

wire pc_stall;
wire if_id_stall;
wire id_ex_stall;
wire ex_mem_stall;
wire mem_wb_stall;
wire fence_stall_idu;
wire fence_stall_exu;
wire fence_stall_mem;
wire fence_stall_dcache;
// fetch_buffer
wire fb_inst_valid;
wire [31:0]fb_inst;
wire [63:0] snpc           ;
wire        inst_j         ;
//===========================================================
//信号定义
//csr
wire [7:0] csr_inst_type_id_csr;
wire [11:0]csr_addr_id_csr;
wire       csr_wen_id_csr;
//wire [63:0]rdata1_reg_csr;/* verilator lint_off UNUSED */

wire [63:0]wdate_csr;

wire time_interrupt;
wire [63:0]snpc_csr_id;
wire [63:0]snpc_ifu;
//wire flash;

wire        axi_icache_arbiter_ar_valid ;
wire        axi_icache_arbiter_ar_ready ;
wire [31:0] axi_icache_arbiter_ar_addr  ;
wire        axi_icache_arbiter_ar_len   ;
wire [2:0]  axi_icache_arbiter_ar_size  ;
wire        axi_icache_arbiter_r_ready  ;
wire        axi_icache_arbiter_r_valid  ;
wire [1:0]  axi_icache_arbiter_r_resp   ;
wire [63:0] axi_icache_arbiter_r_data   ;

wire        axii_ar_valid ;
wire        axii_ar_ready ;
wire [31:0] axii_ar_addr  ;
wire        axii_ar_len   ;
wire [2:0]  axii_ar_size  ;
wire        axii_r_ready  ;
wire        axii_r_valid  ;
wire [63:0] axii_r_data   ;

wire        axi_icache_sram_ar_valid ;
wire        axi_icache_sram_ar_ready ;
wire [31:0] axi_icache_sram_ar_addr  ;
wire        axi_icache_sram_ar_len   ;
wire        axi_icache_sram_r_ready  ;
wire        axi_icache_sram_r_valid ;
wire [1:0]  axi_icache_sram_r_resp   ;
wire [63:0] axi_icache_sram_r_data   ;

wire axi_if_sram_rready;
wire axi_if_sram_rvalid;
wire [127:0]axi_if_sram_rdata;
wire [1:0] axi_if_sram_resp;
wire axi_if_sram_arready;
wire axi_if_sram_arvalid;
wire [31:0]axi_if_sram_araddr;

wire        axi_ifu_icache_ar_ready ;
wire        axi_ifu_icache_ar_valid ;
wire [31:0] axi_ifu_icache_ar_addr  ;
wire        axi_ifu_icache_r_valid  ;
wire [127:0]axi_ifu_icache_r_data   ;
wire [1:0]  axi_ifu_icache_r_resp   ;
wire        axi_ifu_icache_r_ready  ;

wire [63:0] pc_ifu_id  ;
wire [31:0] inst_ifu_id;
wire commite_if_id;

//wire [63:0] inst_addr_id_ex;//decode流水
wire [4:0]  raddr1_id_regs ;//读寄存器1索引
wire [4:0]  raddr2_id_regs ;//读寄存器2索引
wire [63:0] rdata1_id_regs ;//读寄存器1数据
wire [63:0] rdata2_id_regs ;//读寄存器2数据
wire [63:0] op1_id      ;//操作数1
wire [63:0] op2_id      ;//操作数2
wire        reg_we_id   ;//reg写使能
wire [4:0]  reg_waddr_id;//写寄存器的索引
wire [`ysyx_22050019_alu_len:0]alu_sel       ;//alu控制信号


wire        ram_we_id   ;//存储器写使能
wire [63:0] ram_wdata_id;//mem写数据
wire        ram_re_id   ;
wire [5:0]  mem_r_wdth     ;
wire [3:0]  mem_w_wdth     ;
//wire [63:0] rdata1_forwardimg;
//wire [63:0] rdata2_forwardimg;
//wire        forwarding_stall;
wire [4:0]  zimm_id_csr;

wire csr_sel_wen;
wire time_req;

wire         ram_we_id_exu   ;
wire [63:0]  ram_wdata_id_exu;
wire [3:0]   mem_w_wdth_exu  ;
wire         ram_re_id_exu   ;
wire [5:0]   mem_r_wdth_exu  ;
wire [63:0]  op1_id_exu      ;
wire [63:0]  op2_id_exu      ;
wire         reg_we_id_exu   ;
wire [4:0]   reg_waddr_id_exu;
wire [`ysyx_22050019_alu_len:0]alu_sel_exu     ;
wire [63:0]  wdate_csr_exu   ;
wire [63:0]  pc_id_exu       ;
wire [31:0]  inst_id_ex      ;

wire commite_id_ex;

wire [63:0]  wdata_ex_reg  ;
//wire         reg_we_id_exu ;
//wire [4:0]   reg_waddr_id_exu  ;
wire [63:0] result_exu;
wire alu_stall;
wire exu_wen;
wire [4:0]exu_waddr;

wire        wen_lsu_reg;
wire [4:0]  waddr_lsu_reg;
wire lsu_stall_req;

wire [63:0]  result_exu_lsu   ;
wire         ram_we_exu_lsu   ;
wire [63:0]  ram_wdata_exu_lsu;
wire [3:0]   mem_w_wdth_lsu   ;
wire         ram_re_exu_lsu   ;
wire [5:0]   mem_r_wdth_lsu   ;
wire         reg_we_exu_lsu   ;
wire [4:0]   reg_waddr_exu_lsu;
wire [63:0]  wdate_csr_lsu    ;
wire [63:0]  wdata_reg_exu_lsu;

wire [63:0]  pc_exu_mem       ;
wire [31:0]  inst_exu_mem     ;
wire commite_ex_mem;
wire ex_mem_commit ;

//uncache的控制逻辑
wire [31:0] ram_waddr_lsu_mem ;//mem索引
wire [31:0] ram_raddr_lsu_mem ;//mem读索引
wire clint_addr ;
wire cache_max  ;
wire cache_min  ;
wire uncache;
wire [63:0] wdata_lsu_wb;
wire        axi_dcache_arbiter_aw_ready ;
wire        axi_lsu_dcache_aw_ready ;
wire        axi_lsu_sram_aw_ready;
wire        axi_lsu_sram_aw_valid;
wire [63:0] ram_wdata_lsu_mem    ;
wire [7:0]  wmask             ;
wire        axi_lsu_dcache_w_ready  ;
wire        axi_dcache_arbiter_w_ready  ;
wire        axi_lsu_sram_w_ready ;
wire        axi_lsu_sram_w_valid;
wire        axi_lsu_dcache_b_valid  ;
wire [1:0]  axi_lsu_dcache_b_resp   ; 
wire        axi_lsu_dcache_ar_ready ;
wire [1:0]  axi_dcache_arbiter_b_resp   ;
wire [1:0]  axi_lsu_sram_b_wresp ;
wire        axi_lsu_sram_b_ready;
wire        axi_dcache_arbiter_b_valid  ;
wire        axi_lsu_sram_b_valid;
wire        axi_dcache_arbiter_r_valid  ;
wire [1:0]  axi_dcache_arbiter_r_resp   ;
wire [63:0] axi_dcache_arbiter_r_data   ;
wire [63:0] axi_lsu_dcache_r_data   ;
wire [63:0] ram_rdata_mem_lsu;

wire        axi_dcache_arbiter_ar_ready ;
wire        axi_lsu_sram_ar_ready;
wire        axi_lsu_sram_ar_valid;
wire [1:0]  axi_lsu_sram_r_resp;
wire        axi_lsu_sram_r_ready;
wire        axi_lsu_dcache_r_valid  ;
wire        axi_lsu_sram_r_valid;


wire        axi_lsu_dcache_aw_valid ;
wire [31:0] axi_lsu_dcache_aw_addr  ;

wire        axi_lsu_dcache_w_valid  ;
wire [63:0] axi_lsu_dcache_w_data   ;
wire [7:0]  axi_lsu_dcache_w_strb   ;
wire        axi_lsu_dcache_b_ready  ;
 
wire        axi_lsu_dcache_ar_valid ; 
wire [31:0] axi_lsu_dcache_ar_addr  ; 
wire        axi_lsu_dcache_r_ready  ;

wire [1:0]  axi_lsu_dcache_r_resp   ;    


wire        axi_dcache_aw_ready    ;
wire        axi_dcache_aw_valid    ;
wire [31:0] axi_dcache_aw_addr     ;
wire        axi_dcache_rw_len      ;
wire        axi_dcache_w_ready     ;
wire        axi_dcache_w_valid     ;
wire [63:0] axi_dcache_w_data      ;
wire [7:0]  axi_dcache_w_strb      ;
wire        axi_dcache_w_last      ;
wire        axi_dcache_b_ready     ;

wire        axi_dcache_b_valid     ;
wire [1:0]  axi_dcache_b_resp      ;
wire        axi_dcache_ar_ready    ;
wire        axi_dcache_ar_valid    ;
wire [31:0] axi_dcache_ar_addr     ;
wire        axi_dcache_r_ready     ;
wire        axi_dcache_r_valid     ;
wire [1:0]  axi_dcache_r_resp      ;
wire [63:0] axi_dcache_r_data      ;


wire        axi_dcache_arbiter_aw_valid ;
wire [31:0] axi_dcache_arbiter_aw_addr  ;
wire        axi_dcache_arbiter_rw_len   ;
wire [2:0]  axi_lsu_aw_size;
wire [2:0]  axi_dcache_arbiter_aw_size  ;

wire        axi_dcache_arbiter_w_valid  ;
wire [63:0] axi_dcache_arbiter_w_data   ;
wire [7:0]  axi_dcache_arbiter_w_strb   ;
wire        axi_dcache_arbiter_b_ready  ;
wire        axi_dcache_arbiter_w_last   ;


wire        axi_dcache_arbiter_ar_valid ;
wire [31:0] axi_dcache_arbiter_ar_addr  ;
wire [2:0]  axi_lsu_ar_size;
wire [2:0]  axi_dcache_arbiter_ar_size  ;
wire        axi_dcache_arbiter_r_ready  ;

wire s1_axi_aw_ready_o;
wire s1_axi_w_ready_o ;
wire s1_axi_b_valid_o ;
wire [1:0] s1_axi_b_resp_o;

wire         reg_we_wbu   ;
wire [4:0]   reg_waddr_wbu;
wire [63:0]  reg_wdata_wbu;

wire commite_mem_wb;
wire         reg_we_wb    ;
wire [4:0]   reg_waddr_wb ;
wire [63:0]  reg_wdata_wb ;
wire mem_wb_commit ;
`ifdef ysyx_22050019_dpic
wire [63:0]csr_regs_diff[3:0];
wire [63:0]csr_regs_diff_exu[3:0];
wire [63:0]csr_regs_diff_lsu[3:0];
wire [63:0]csr_regs_diff_wbu[3:0];
`endif

//===========================================================
assign pc_ifu[63:32] = 0;
assign snpc_ifu = time_interrupt ? snpc_csr_id : snpc|snpc_csr_id;

//fetch模块端口
ysyx_22050019_IFU IFU(
    .clk           ( clock              ),
    .rst_n         ( reset            ),
    .inst_j        ( inst_j|time_interrupt  ),
    .snpc          ( snpc_ifu[31:0]         ),
    .inst_i        ( fb_inst          ),
    .inst_valid_i  ( fb_inst_valid    ),
    .inst_commite  ( ifu_commite      ),
    .pc_stall_i    ( pc_stall         ),
    .inst_addr_o   ( pc_ifu[31:0]           ),
    .inst_o        ( inst_ifu         )
);



//icache的缓存区设置
//wire        axi_icache_sram_ar_valid ;
assign        axi_icache_sram_ar_ready = axi_icache_arbiter_ar_ready;
//wire [31:0] axi_icache_sram_ar_addr  ;
//wire        axi_icache_sram_ar_len   ;
//wire        axi_icache_sram_r_ready  ;
assign        axi_icache_sram_r_valid  = axi_icache_arbiter_r_valid;
assign        axi_icache_sram_r_resp   = axi_icache_arbiter_r_resp;
assign        axi_icache_sram_r_data   = axi_icache_arbiter_r_data;

//wire axi_if_sram_rready;
//wire axi_if_sram_rvalid;
//wire [127:0]axi_if_sram_rdata;
assign        axi_if_sram_resp  = 0;
//wire axi_if_sram_arready;
//wire axi_if_sram_arvalid;
//wire [31:0]axi_if_sram_araddr;

assign axi_if_sram_arvalid = axi_ifu_icache_ar_valid;
assign axi_if_sram_araddr  = axi_ifu_icache_ar_addr;
assign axi_if_sram_rready  = axi_ifu_icache_r_ready;

//IFU_flash直通线引入
assign        axi_ifu_icache_ar_ready = axi_if_sram_arready;
//wire        axi_ifu_icache_ar_valid ;
//wire [31:0] axi_ifu_icache_ar_addr  ;
assign        axi_ifu_icache_r_valid  = axi_if_sram_rvalid;
assign        axi_ifu_icache_r_data   = axi_if_sram_rdata;
assign        axi_ifu_icache_r_resp   = axi_if_sram_resp;
//wire        axi_ifu_icache_r_ready  ;

//arbiter
assign        axi_icache_arbiter_ar_valid = axi_icache_sram_ar_valid;
assign        axi_icache_arbiter_ar_addr  = axi_icache_sram_ar_addr;
assign        axi_icache_arbiter_ar_len   = axi_icache_sram_ar_len;
assign        axi_icache_arbiter_ar_size  = 3'b011;
assign        axi_icache_arbiter_r_ready  = axi_icache_sram_r_ready ;

ysyx_22050019_axi_interconnect u_ysyx_22050019_axi_interconnect(
    .clk                  ( clock                  ),
    .rst                  ( reset                  ),
    .axii_icache_ar_ready ( axi_icache_arbiter_ar_ready ),
    .axii_icache_ar_valid ( axi_icache_arbiter_ar_valid ),
    .axii_icache_ar_addr  ( axi_icache_arbiter_ar_addr  ),
    .axii_icache_ar_len   ( axi_icache_arbiter_ar_len   ),
    .axii_icache_ar_size  ( axi_icache_arbiter_ar_size  ),
    .axii_icache_r_ready  ( axi_icache_arbiter_r_ready  ),
    .axii_icache_r_valid  ( axi_icache_arbiter_r_valid  ),
    .axii_icache_r_data   ( axi_icache_arbiter_r_data   ),
    .axii_ar_ready        ( axii_ar_ready        ),
    .axii_ar_valid        ( axii_ar_valid        ),
    .axii_ar_addr         ( axii_ar_addr         ),
    .axii_ar_len          ( axii_ar_len          ),
    .axii_ar_size         ( axii_ar_size         ),
    .axii_r_ready         ( axii_r_ready         ),
    .axii_r_valid         ( axii_r_valid         ),
    .axii_r_data          ( axii_r_data          )
);


ysyx_22050019_fetch_buffer IB(
    .clk          ( clock                   ),
    .rst_n        ( reset                 ),
    .ar_ready_i   ( axi_ifu_icache_ar_ready   ),
    .ar_valid_o   ( axi_ifu_icache_ar_valid   ),
    .ar_addr_o    ( axi_ifu_icache_ar_addr    ),
    .r_valid_i    ( axi_ifu_icache_r_valid    ),
    .r_data_i     ( axi_ifu_icache_r_data     ),
    .r_resp_i     ( axi_ifu_icache_r_resp      ),
    .r_ready_o    ( axi_ifu_icache_r_ready    ),
//    .jmp_flush_i  ( inst_j|time_interrupt|fence_stall_idu),
    .stall_ib     ( pc_stall | inst_j|time_interrupt|fence_stall_idu),
    .pc_i         ( pc_ifu[31:0]          ),
//    .flash        ( flash                 ),
    .inst_valid_o ( fb_inst_valid         ),
    .inst_o       ( fb_inst               )
);

//==================IF/ID=======================


ysyx_22050019_IF_ID IF_ID(
    .clk          ( clock          ),
    .rst_n        ( reset        ),
    .commite_i    ( ifu_commite  ),
    .pc_i         ( pc_ifu       ),
    .inst_i       ( inst_ifu     ),
    .commite_o    ( commite_if_id),
    .if_id_stall_i( if_id_stall  ),
    .id_ex_stall_i( id_ex_stall  ),
    .id_j_flush   ( pc_stall|inst_j|time_interrupt|fence_stall_idu),
    .pc_o         ( pc_ifu_id    ),
    .inst_o       ( inst_ifu_id  )
);


//decode模块端口
ysyx_22050019_IDU IDU(
 .inst_addr_pc (pc_ifu_id            ),
 .inst_i       (inst_ifu_id          ),
 
 .snpc         (snpc                 ),
 .inst_j       (inst_j               ),
 .fence_stall  (fence_stall_idu      ),
 .ram_we       (ram_we_id            ),
 .ram_wdata    (ram_wdata_id         ),
 .ram_re       (ram_re_id            ),

 .raddr1       (raddr1_id_regs       ),
 .rdata1       (rdata1_id_regs    ),
 .raddr2       (raddr2_id_regs       ),
 .rdata2       (rdata2_id_regs    ),
 .op1          (op1_id               ),
 .op2          (op2_id               ),
 .reg_we_o     (reg_we_id            ),
 .reg_waddr_o  (reg_waddr_id         ),

 .csr_inst_type(csr_inst_type_id_csr ),
 .csr_wen      (csr_wen_id_csr       ),
 .csr_addr     (csr_addr_id_csr      ),
 .zimm         (zimm_id_csr          ),

 .mem_r_wdth   (mem_r_wdth           ),
 .mem_w_wdth   (mem_w_wdth           ),
 .alu_sel      (alu_sel              )        
);

/*csr模块的寄存器模块单独列出
目前实现指令
csrw 读csr，将x[rs1]的值写入csr，原来的csr值写回x[rd]
ecall snpc->mtvec,把当前pc保存给mepc，把异常号0xb给mcause
目前实现寄存器
mtvec   存储异常地址入口寄存器，由csrw存入，ecall跳转
mepc    存入发生异常时pc
mcause  根据异常原因存入相应异常情况
mstatus 机械模式寄存器，只实现m模式
小尝试，考虑小范围的使用always在某些地方比写mux能方便些,always（*）在综合时reg信号也视作一根线
*/
assign csr_sel_wen =id_ex_stall ? 1'b0: csr_wen_id_csr ;
ysyx_22050019_CSR CSR(
    .clk             (clock                 ),
    .rst_n           (reset               ),
    .pc              (pc_ifu_id           ),
  
    .csr_inst_type   (csr_inst_type_id_csr),
    .csr_addr        (csr_addr_id_csr     ),
    .csr_wen         (csr_sel_wen         ),
    .rdata1_reg_csr  (rdata1_id_regs   ),//从reg读到的数据
    .zimm            (zimm_id_csr         ),
    .time_req        (time_req),
    .stall_nop       (~id_ex_stall&&~fence_stall_idu&&(|inst_ifu_id)&&~csr_sel_wen),
    .time_interrupt  (time_interrupt      ),

    .snpc            (snpc_csr_id         ),
`ifdef ysyx_22050019_dpic
    .csr_regs_diff   (csr_regs_diff       ),//csr to reg for diff
`endif

    .wdate_csr_reg   (wdate_csr           )//向reg写的数据
    

);

//==================ID/EX=======================


ysyx_22050019_ID_EX ID_EX(
    .clk              ( clock              ),
    .rst_n            ( reset            ),
    .pc_i             ( pc_ifu_id        ),
    .inst_i           ( inst_ifu_id      ),
    .commite_i        ( commite_if_id    ),
    .fence_stall_i    ( fence_stall_idu  ),
    .ram_we_i         ( ram_we_id        ),
    .ram_wdata_i      ( ram_wdata_id     ),
    .mem_w_wdth_i     ( mem_w_wdth       ),
    .ram_re_i         ( ram_re_id        ),
    .mem_r_wdth_i     ( mem_r_wdth       ),
    .op1_i            ( op1_id           ),
    .op2_i            ( op2_id           ),
    .reg_we_i         ( reg_we_id        ),
    .reg_waddr_i      ( reg_waddr_id     ),
    .alu_sel_i        ( alu_sel          ),
    .wdate_csr_reg_i  ( wdate_csr        ),

`ifdef ysyx_22050019_dpic
    .csr_regs_diff_i  ( csr_regs_diff    ),
    .csr_regs_diff_o  ( csr_regs_diff_exu),
`endif
// control
    .id_ex_stall_i    ( id_ex_stall      ),
    .time_interrupt   (time_interrupt),
    .ex_mem_stall_i   ( ex_mem_stall     ),

    .pc_o             ( pc_id_exu        ),
    .inst_o           ( inst_id_ex       ),
    .commite_o        ( commite_id_ex    ),
    .fence_stall_o    ( fence_stall_exu  ),
    .ram_we_o         ( ram_we_id_exu    ),
    .ram_wdata_o      ( ram_wdata_id_exu ),
    .mem_w_wdth_o     ( mem_w_wdth_exu   ),
    .ram_re_o         ( ram_re_id_exu    ),
    .mem_r_wdth_o     ( mem_r_wdth_exu   ),
    .op1_o            ( op1_id_exu       ),
    .op2_o            ( op2_id_exu       ),
    .reg_we_o         ( reg_we_id_exu    ),
    .reg_waddr_o      ( reg_waddr_id_exu ),
    .alu_sel_o        ( alu_sel_exu      ),
    .wdate_csr_reg_o  ( wdate_csr_exu    )

);

//EXecut模块端口

ysyx_22050019_EXU EXU(
 .clk         (clock         ),
 .rst_n       (reset       ),
 .alu_sel     (alu_sel_exu ),
 .wen_i       (reg_we_id_exu ),
 .waddr_i     (reg_waddr_id_exu),
 .lsu_stall   (lsu_stall_req),
 .op1         (op1_id_exu  ),
 .op2         (op2_id_exu  ),

 .alu_stall   (alu_stall   ),
 .exu_wen     (exu_wen     ),
 .exu_waddr   (exu_waddr   ),
 .result      (result_exu  ),
 .wdata       (wdata_ex_reg)
);

//==================EX/MEM======================
//wire [63:0]  result_exu_lsu   ;
//wire         ram_we_exu_lsu   ;
//wire [63:0]  ram_wdata_exu_lsu;
//wire [3:0]   mem_w_wdth_lsu   ;
//wire         ram_re_exu_lsu   ;
//wire [5:0]   mem_r_wdth_lsu   ;
//wire         reg_we_exu_lsu   ;
//wire [4:0]   reg_waddr_exu_lsu;
//wire [63:0]  wdate_csr_lsu    ;
//wire [63:0]  wdata_reg_exu_lsu;
//wire [63:0]  pc_exu_mem       ;
//wire [31:0]  inst_exu_mem     ;
//wire commite_ex_mem;
assign ex_mem_commit = alu_stall ? 0 : commite_id_ex | exu_wen;

ysyx_22050019_EX_MEM EX_MEM(
    .clk              ( clock              ),
    .rst_n            ( reset            ),
    .pc_i             ( pc_id_exu        ),
    .inst_i           ( inst_id_ex       ),
    .commite_i        ( ex_mem_commit    ),
    .fence_stall_i    ( fence_stall_exu  ),
    .result_i         ( result_exu       ),
    .wdata_exu_reg_i  ( wdata_ex_reg     ),
    .ram_we_i         ( ram_we_id_exu    ),
    .ram_wdata_i      ( ram_wdata_id_exu ),
    .mem_w_wdth_i     ( mem_w_wdth_exu   ),
    .ram_re_i         ( ram_re_id_exu    ),
    .mem_r_wdth_i     ( mem_r_wdth_exu   ),
    .reg_we_i         ( exu_wen          ),
    .reg_waddr_i      ( exu_waddr        ),
    .wdate_csr_reg_i  ( wdate_csr_exu    ),

`ifdef ysyx_22050019_dpic
    .csr_regs_diff_i  ( csr_regs_diff_exu),
    .csr_regs_diff_o  ( csr_regs_diff_lsu),
`endif
// comtrol
    .ex_mem_stall_i   ( ex_mem_stall     ),
    .mem_wb_stall_i   ( mem_wb_stall     ),

    .pc_o             ( pc_exu_mem       ),
    .inst_o           ( inst_exu_mem     ), 
    .commite_o        ( commite_ex_mem   ),
    .fence_stall_o    ( fence_stall_mem  ),
    .result_o         ( result_exu_lsu   ),
    .wdata_exu_reg_o  ( wdata_reg_exu_lsu),
    .ram_we_o         ( ram_we_exu_lsu   ),
    .ram_wdata_o      ( ram_wdata_exu_lsu),
    .mem_w_wdth_o     ( mem_w_wdth_lsu   ),
    .ram_re_o         ( ram_re_exu_lsu   ),
    .mem_r_wdth_o     ( mem_r_wdth_lsu   ),
    .reg_we_o         ( reg_we_exu_lsu   ),
    .reg_waddr_o      ( reg_waddr_exu_lsu),
    .wdate_csr_reg_o  ( wdate_csr_lsu    )

);
//***********************************************************************
// dcache的信号处理模块，包含uncache和的cache的分流处理
//***********************************************************************
//uncache的控制逻辑
//wire [31:0] ram_waddr_lsu_mem ;//mem索引
//wire [31:0] ram_raddr_lsu_mem ;//mem读索引
//wire uncache=(((ram_waddr_lsu_mem|ram_raddr_lsu_mem)<32'h80000000)||(ram_waddr_lsu_mem|ram_raddr_lsu_mem)>32'h88000000);
assign clint_addr = ((ram_waddr_lsu_mem>32'h1ffffff&&ram_waddr_lsu_mem<32'h2010000)|ram_raddr_lsu_mem>32'h1ffffff&&ram_raddr_lsu_mem<32'h2010000);//0x0200_0000<->0x0200_ffff
assign cache_max = ((ram_waddr_lsu_mem|ram_raddr_lsu_mem)<32'h80000000) & ~clint_addr;

//wire uncache= ~clint_addr;//pc空间，clint空间
`ifdef ysyx_22050019_dpic
assign cache_min = ((ram_waddr_lsu_mem|ram_raddr_lsu_mem)>32'h88000000);
assign uncache=(cache_max | cache_min) & ~fence_stall_dcache;
`else
assign uncache=cache_max & ~fence_stall_dcache;//pc空间，clint空间
`endif


// lsu模块端口
//wire [63:0] wdata_lsu_wb;
//wire        ram_we_lsu_mem   ;//存储器写使能
//wire        axi_dcache_arbiter_aw_ready ;
//wire        axi_lsu_dcache_aw_ready ;
assign        axi_lsu_sram_aw_ready = uncache ? axi_dcache_arbiter_aw_ready  : axi_lsu_dcache_aw_ready;
//wire        axi_lsu_sram_aw_valid;
//wire [63:0] ram_wdata_lsu_mem    ;
//wire [7:0]  wmask             ;
//wire        axi_lsu_dcache_w_ready  ;
//wire        axi_dcache_arbiter_w_ready  ;
assign        axi_lsu_sram_w_ready  = uncache ? axi_dcache_arbiter_w_ready   : axi_lsu_dcache_w_ready ;
//wire        axi_lsu_sram_w_valid;
//wire        axi_lsu_dcache_b_valid  ;
//wire [1:0]  axi_lsu_dcache_b_resp   ; 
//wire        axi_lsu_dcache_ar_ready ;
//wire [1:0]  axi_dcache_arbiter_b_resp   ;
assign        axi_lsu_sram_b_wresp  = uncache ? axi_dcache_arbiter_b_resp    : axi_lsu_dcache_b_resp  ;
//wire        axi_lsu_sram_b_ready;
//wire        axi_dcache_arbiter_b_valid  ;
assign        axi_lsu_sram_b_valid  = uncache ? axi_dcache_arbiter_b_valid   : axi_lsu_dcache_b_valid ;
//wire        ram_re_lsu_mem   ;//存储器读使能
//wire        axi_dcache_arbiter_r_valid  ;
//wire [1:0]  axi_dcache_arbiter_r_resp   ;
//wire [63:0] axi_dcache_arbiter_r_data   ;
//wire [63:0] axi_lsu_dcache_r_data   ;
assign        ram_rdata_mem_lsu     = uncache ? axi_dcache_arbiter_r_data    : axi_lsu_dcache_r_data;

//wire        axi_dcache_arbiter_ar_ready ;
assign        axi_lsu_sram_ar_ready = uncache ? axi_dcache_arbiter_ar_ready  : axi_lsu_dcache_ar_ready;
//wire        axi_lsu_sram_ar_valid;
assign        axi_lsu_sram_r_resp = 0;
//wire        axi_lsu_sram_r_ready;
//wire        axi_lsu_dcache_r_valid  ;
assign        axi_lsu_sram_r_valid  = uncache ? axi_dcache_arbiter_r_valid : axi_lsu_dcache_r_valid;



ysyx_22050019_LSU LSU(
 .clk            (clock                  ),
 .rst            (reset                ),
 .result         (result_exu_lsu       ),
 .ram_we_i       (ram_we_exu_lsu       ),
 .ram_wdata_i    (ram_wdata_exu_lsu    ),
 .ram_re_i       (ram_re_exu_lsu       ),
 
 .mem_r_wdth     (mem_r_wdth_lsu       ),
 .mem_w_wdth     (mem_w_wdth_lsu       ),
   
 //.ram_we       (ram_we_lsu_mem),
 .ram_waddr      (ram_waddr_lsu_mem    ),
 .m_axi_aw_ready (axi_lsu_sram_aw_ready),
 .m_axi_aw_valid (axi_lsu_sram_aw_valid),
 .ram_wdata      (ram_wdata_lsu_mem    ),
 .wmask          (wmask                ),
 .m_axi_w_ready  (axi_lsu_sram_w_ready ),
 .m_axi_w_valid  (axi_lsu_sram_w_valid ),
 .ram_wresp_i    (axi_lsu_sram_b_wresp ),
 .m_axi_b_ready  (axi_lsu_sram_b_ready ),
 .m_axi_b_valid  (axi_lsu_sram_b_valid ),
 //.ram_re         (ram_re_lsu_mem),
 .ram_raddr      (ram_raddr_lsu_mem    ),
 .m_axi_ar_ready (axi_lsu_sram_ar_ready),
 .m_axi_ar_valid (axi_lsu_sram_ar_valid),
 .ram_rdata_i    (ram_rdata_mem_lsu    ),
 .m_axi_r_resp   (axi_lsu_sram_r_resp  ),
 .m_axi_r_ready  (axi_lsu_sram_r_ready ),
 .m_axi_r_valid  (axi_lsu_sram_r_valid ),

// control

 .lsu_stall_req  (lsu_stall_req        ),

 .waddr_reg_i    (reg_waddr_exu_lsu    ),
 .wen_reg_o      (wen_lsu_reg          ),
 .waddr_reg_o    (waddr_lsu_reg        ),
 .wdata_reg_o    (wdata_lsu_wb         )
);




ysyx_22050019_icache I_CACHE(
    .clk               ( clock                      ),
    .rst               ( reset                    ),

    .fence_i           ( fence_stall_idu          ),
    .ar_valid_i        ( axi_if_sram_arvalid      ),
    .ar_ready_o        ( axi_if_sram_arready      ),
    .ar_addr_i         ( axi_if_sram_araddr       ),
    .r_data_valid_o    ( axi_if_sram_rvalid       ),
    .r_data_ready_i    ( axi_if_sram_rready       ),
    .r_resp_i          ( axi_if_sram_resp         ),
    .r_data_o          ( axi_if_sram_rdata        ),
    .io_sram0_addr     ( io_sram0_addr            ),
    .io_sram0_cen      ( io_sram0_cen             ),
    .io_sram0_wen      ( io_sram0_wen             ),
    .io_sram0_wmask    ( io_sram0_wmask           ),
    .io_sram0_wdata    ( io_sram0_wdata           ),
    .io_sram0_rdata    ( io_sram0_rdata           ),
    .io_sram1_addr     ( io_sram1_addr            ),
    .io_sram1_cen      ( io_sram1_cen             ),
    .io_sram1_wen      ( io_sram1_wen             ),
    .io_sram1_wmask    ( io_sram1_wmask           ),
    .io_sram1_wdata    ( io_sram1_wdata           ),
    .io_sram1_rdata    ( io_sram1_rdata           ),
    .cache_ar_valid_o  ( axi_icache_sram_ar_valid ),
    .cache_ar_ready_i  ( axi_icache_sram_ar_ready ),
    .cache_ar_addr_o   ( axi_icache_sram_ar_addr  ),
    .cache_ar_len_o    ( axi_icache_sram_ar_len   ),
    .cache_r_ready_o   ( axi_icache_sram_r_ready  ),
    .cache_r_valid_i   ( axi_icache_sram_r_valid  ),
    .cache_r_resp_i    ( axi_icache_sram_r_resp   ),
    .cache_r_data_i    ( axi_icache_sram_r_data   )
);


//=======================================================================
//dcache与uncache信号的生成与选择控制

assign        axi_lsu_dcache_aw_valid = uncache ? 0 : axi_lsu_sram_aw_valid;
assign  axi_lsu_dcache_aw_addr  = uncache ? 0 : ram_waddr_lsu_mem    ;

assign  axi_lsu_dcache_w_valid  = uncache ? 0 : axi_lsu_sram_w_valid ;
assign  axi_lsu_dcache_w_data   = uncache ? 0 : ram_wdata_lsu_mem    ;
assign  axi_lsu_dcache_w_strb   = uncache ? 0 : wmask                ;
assign        axi_lsu_dcache_b_ready  = uncache ? 0 : axi_lsu_sram_b_ready ;
 
assign        axi_lsu_dcache_ar_valid = uncache ? 0 : axi_lsu_sram_ar_valid; 
assign  axi_lsu_dcache_ar_addr  = uncache ? 0 : ram_raddr_lsu_mem    ; 
assign        axi_lsu_dcache_r_ready  = uncache ? 0 : axi_lsu_sram_r_ready ;

assign   axi_lsu_dcache_r_resp   = uncache ? 0 : axi_lsu_sram_r_resp  ;    


assign        axi_dcache_aw_ready    = uncache ? 0 : axi_dcache_arbiter_aw_ready  ; 
//wire        axi_dcache_aw_valid    ;
//wire  axi_dcache_aw_addr     ;
//wire  axi_dcache_rw_len      ;
assign  axi_dcache_w_ready     = uncache ? 0 : axi_dcache_arbiter_w_ready   ; 
//wire  axi_dcache_w_valid     ;
//wire  axi_dcache_w_data      ;
//wire  axi_dcache_w_strb      ;
//wire  axi_dcache_w_last      ;
//wire  axi_dcache_b_ready     ;

assign  axi_dcache_b_valid     = uncache ? 0 : axi_dcache_arbiter_b_valid   ; 
assign  axi_dcache_b_resp      = uncache ? 0 : axi_dcache_arbiter_b_resp    ; 
assign  axi_dcache_ar_ready    = uncache ? 0 : axi_dcache_arbiter_ar_ready  ; 
//wire  axi_dcache_ar_valid    ;
//wire  axi_dcache_ar_addr     ;
//wire  axi_dcache_r_ready     ;
assign  axi_dcache_r_valid     = uncache ? 0 : axi_dcache_arbiter_r_valid   ; 
assign  axi_dcache_r_resp      = uncache ? 0 : axi_dcache_arbiter_r_resp    ; 
assign  axi_dcache_r_data      = uncache ? 0 : axi_dcache_arbiter_r_data    ; 


assign  axi_dcache_arbiter_aw_valid = uncache ? axi_lsu_sram_aw_valid  : axi_dcache_aw_valid ;
assign  axi_dcache_arbiter_aw_addr  = uncache ? ram_waddr_lsu_mem[31:0]: axi_dcache_aw_addr  ;
assign  axi_dcache_arbiter_rw_len   = uncache ? 0                     : axi_dcache_rw_len   ;
//wire  axi_lsu_aw_size;
assign axi_lsu_aw_size[0] = mem_w_wdth_lsu[3] | mem_w_wdth_lsu[1] ;
assign axi_lsu_aw_size[1] = mem_w_wdth_lsu[3] | mem_w_wdth_lsu[0] ; 
assign axi_lsu_aw_size[2] = 0; 
assign  axi_dcache_arbiter_aw_size  = uncache ? axi_lsu_aw_size       : 3'b011   ;

assign  axi_dcache_arbiter_w_valid  = uncache ? axi_lsu_sram_w_valid  : axi_dcache_w_valid  ;
assign  axi_dcache_arbiter_w_data   = uncache ? ram_wdata_lsu_mem     : axi_dcache_w_data   ;
assign  axi_dcache_arbiter_w_strb   = uncache ? wmask                 : axi_dcache_w_strb   ;
assign  axi_dcache_arbiter_b_ready  = uncache ? axi_lsu_sram_b_ready  : axi_dcache_b_ready  ;
assign  axi_dcache_arbiter_w_last   = uncache ? 1'b1                  : axi_dcache_w_last   ;


assign        axi_dcache_arbiter_ar_valid = uncache ? axi_lsu_sram_ar_valid : axi_dcache_ar_valid ;
assign  axi_dcache_arbiter_ar_addr  = uncache ? ram_raddr_lsu_mem[31:0]     : axi_dcache_ar_addr;
//wire [2:0]  axi_lsu_ar_size;
assign axi_lsu_ar_size[0] = mem_r_wdth_lsu[4] | mem_r_wdth_lsu[1] ;
assign axi_lsu_ar_size[1] = mem_r_wdth_lsu[5] | mem_r_wdth_lsu[2] ; 
assign axi_lsu_ar_size[2] = 1'b0;
assign        axi_dcache_arbiter_ar_size  = uncache ? axi_lsu_ar_size : 3'b011;
assign        axi_dcache_arbiter_r_ready  = uncache ? axi_lsu_sram_r_ready  : axi_dcache_r_ready  ;

//wire debug_aw_addr = axi_dcache_arbiter_aw_addr == 32'h80010790;
ysyx_22050019_dcache D_CACHE(
    .clk               ( clock                            ),
    .rst               ( reset                          ),
    .clint_addr        ( clint_addr                     ),
    .time_req          ( time_req                       ),
    .fence_i           ( fence_stall_mem               ),
    .ar_valid_i        ( axi_lsu_dcache_ar_valid        ),
    .ar_ready_o        ( axi_lsu_dcache_ar_ready        ),
    .ar_addr_i         ( axi_lsu_dcache_ar_addr         ),
    .r_data_valid_o    ( axi_lsu_dcache_r_valid         ),
    .r_data_ready_i    ( axi_lsu_dcache_r_ready         ),
    .r_resp_i          ( axi_lsu_dcache_r_resp          ),
    .r_data_o          ( axi_lsu_dcache_r_data          ),
    .aw_valid_i        ( axi_lsu_dcache_aw_valid        ),
    .aw_ready_o        ( axi_lsu_dcache_aw_ready        ),
    .aw_addr_i         ( axi_lsu_dcache_aw_addr         ),
    .w_data_valid_i    ( axi_lsu_dcache_w_valid         ),
    .w_data_ready_o    ( axi_lsu_dcache_w_ready         ),
    .w_w_strb_i        ( axi_lsu_dcache_w_strb          ),
    .w_data_i          ( axi_lsu_dcache_w_data          ),
    .b_ready_i         ( axi_lsu_dcache_b_ready         ),
    .b_valid_o         ( axi_lsu_dcache_b_valid         ),
    .b_resp_o          ( axi_lsu_dcache_b_resp          ),
    .io_sram2_addr     ( io_sram2_addr        ), 
    .io_sram2_cen      ( io_sram2_cen         ), 
    .io_sram2_wen      ( io_sram2_wen         ), 
    .io_sram2_wmask    ( io_sram2_wmask       ), 
    .io_sram2_wdata    ( io_sram2_wdata       ), 
    .io_sram2_rdata    ( io_sram2_rdata       ), 
    .io_sram3_addr     ( io_sram3_addr        ), 
    .io_sram3_cen      ( io_sram3_cen         ), 
    .io_sram3_wen      ( io_sram3_wen         ), 
    .io_sram3_wmask    ( io_sram3_wmask       ), 
    .io_sram3_wdata    ( io_sram3_wdata       ), 
    .io_sram3_rdata    ( io_sram3_rdata       ), 
    .fence_stall_o     ( fence_stall_dcache   ), 
    .cache_aw_valid_o  ( axi_dcache_aw_valid  ),
    .cache_aw_ready_i  ( axi_dcache_aw_ready  ),
    .cache_aw_addr_o   ( axi_dcache_aw_addr   ),
    .cache_rw_len_o    ( axi_dcache_rw_len    ),
    .cache_w_ready_i   ( axi_dcache_w_ready   ),
    .cache_w_valid_o   ( axi_dcache_w_valid   ),
    .cache_w_data_o    ( axi_dcache_w_data    ),
    .cache_w_strb_o    ( axi_dcache_w_strb    ),
    .cache_w_last_o    ( axi_dcache_w_last    ),   
    .cache_b_ready_o   ( axi_dcache_b_ready   ),
    .cache_b_valid_i   ( axi_dcache_b_valid   ),
    .cache_b_resp_i    ( axi_dcache_b_resp    ),
    .cache_ar_valid_o  ( axi_dcache_ar_valid  ),
    .cache_ar_ready_i  ( axi_dcache_ar_ready  ),
    .cache_ar_addr_o   ( axi_dcache_ar_addr   ),
    .cache_r_ready_o   ( axi_dcache_r_ready   ),
    .cache_r_valid_i   ( axi_dcache_r_valid   ),
    .cache_r_resp_i    ( axi_dcache_r_resp    ),
    .cache_r_data_i    ( axi_dcache_r_data    )
);

//***********************************************************************
//ifu没有写同到访问，这里用拉空接地来表示方便仿真

// ifu和lsu的仲裁

// 目前只做了读通道的仲裁，写通道展示没有需要仲裁的冲突点
ysyx_22050133_axi_arbiter ARBITER(
    .clk               ( clock                         ),
    .rst               ( reset                       ),

    // IFU<>ARBITER
    // Advanced eXtensible Interface Slave1
    .s1_axi_aw_ready_o ( s1_axi_aw_ready_o           ),
    .s1_axi_aw_valid_i ( 1'b0                        ),
    .s1_axi_aw_addr_i  ( 32'b0                       ),

    .s1_axi_w_ready_o  ( s1_axi_w_ready_o            ),
    .s1_axi_w_valid_i  ( 1'b0                        ),
    .s1_axi_w_data_i   ( 64'b0                       ),
    .s1_axi_w_strb_i   ( 8'b0                        ),

    .s1_axi_b_ready_i  ( 1'b0                        ),
    .s1_axi_b_valid_o  ( s1_axi_b_valid_o            ),
    .s1_axi_b_resp_o   ( s1_axi_b_resp_o             ),

    .s1_axi_ar_valid_i ( axii_ar_valid    ),
    .s1_axi_ar_ready_o ( axii_ar_ready    ),
    .s1_axi_ar_addr_i  ( axii_ar_addr     ),
    .s1_axi_ar_len_i   ( axii_ar_len      ),
    .s1_axi_ar_size_i  ( axii_ar_size     ),

    .s1_axi_r_valid_o  ( axii_r_valid     ),
    .s1_axi_r_ready_i  ( axii_r_ready     ),
    .s1_axi_r_resp_o   ( axi_icache_arbiter_r_resp      ),
    .s1_axi_r_data_o   ( axii_r_data      ),

    //LSU<>ARBITER
    // Advanced eXtensible Interface Slave2
    .s2_axi_aw_ready_o ( axi_dcache_arbiter_aw_ready ),
    .s2_axi_aw_valid_i ( axi_dcache_arbiter_aw_valid ),
    .s2_axi_aw_addr_i  ( axi_dcache_arbiter_aw_addr  ),
    .s2_axi_rw_len_i   ( axi_dcache_arbiter_rw_len   ),
    .s2_axi_aw_size_i  ( axi_dcache_arbiter_aw_size  ),

    .s2_axi_w_ready_o  ( axi_dcache_arbiter_w_ready  ),
    .s2_axi_w_valid_i  ( axi_dcache_arbiter_w_valid  ),
    .s2_axi_w_data_i   ( axi_dcache_arbiter_w_data   ),
    .s2_axi_w_strb_i   ( axi_dcache_arbiter_w_strb   ),
    .s2_axi_w_last_i   ( axi_dcache_arbiter_w_last   ),

    .s2_axi_b_ready_i  ( axi_dcache_arbiter_b_ready  ),
    .s2_axi_b_valid_o  ( axi_dcache_arbiter_b_valid  ),
    .s2_axi_b_resp_o   ( axi_dcache_arbiter_b_resp   ),

    .s2_axi_ar_ready_o ( axi_dcache_arbiter_ar_ready ),
    .s2_axi_ar_valid_i ( axi_dcache_arbiter_ar_valid ),
    .s2_axi_ar_addr_i  ( axi_dcache_arbiter_ar_addr  ),
    .s2_axi_ar_size_i  ( axi_dcache_arbiter_ar_size   ),
    
    .s2_axi_r_ready_i  ( axi_dcache_arbiter_r_ready  ),
    .s2_axi_r_valid_o  ( axi_dcache_arbiter_r_valid  ),
    .s2_axi_r_resp_o   ( axi_dcache_arbiter_r_resp   ),
    .s2_axi_r_data_o   ( axi_dcache_arbiter_r_data   ),
    
    // arbiter<>sram
    // Advanced eXtensible Interface  Master
    .axi_aw_ready_i    ( io_master_awready    ),
    .axi_aw_valid_o    ( io_master_awvalid    ),
    .axi_aw_addr_o     ( io_master_awaddr     ),
    .axi_aw_len_o      ( io_master_awlen      ),
    .axi_aw_id_o       ( io_master_awid),
    .axi_aw_size_o     ( io_master_awsize),
    .axi_aw_burst_o    ( io_master_awburst),

    .axi_w_ready_i     ( io_master_wready     ),
    .axi_w_valid_o     ( io_master_wvalid     ),
    .axi_w_data_o      ( io_master_wdata      ),
    .axi_w_strb_o      ( io_master_wstrb      ),
    .axi_w_last_o      ( io_master_wlast),

    .axi_b_ready_o     ( io_master_bready     ),
    .axi_b_valid_i     ( io_master_bvalid     ),
    .axi_b_id_i        ( io_master_bid),
    .axi_b_resp_i      ( io_master_bresp      ),
    
    .axi_ar_ready_i    ( io_master_arready    ),
    .axi_ar_valid_o    ( io_master_arvalid    ),
    .axi_ar_addr_o     ( io_master_araddr     ),
    .axi_ar_len_o      ( io_master_arlen      ),
    .axi_ar_id_o       ( io_master_arid),
    .axi_ar_size_o     ( io_master_arsize),
    .axi_ar_burst_o    ( io_master_arburst),
    
    .axi_r_id_i        ( io_master_rid),
    .axi_r_last_i      ( io_master_rlast),
    .axi_r_ready_o     ( io_master_rready     ),
    .axi_r_valid_i     ( io_master_rvalid     ),
    .axi_r_resp_i      ( io_master_rresp      ),
    .axi_r_data_i      ( io_master_rdata      )
);

//==================MEM/WBU=====================
//wb回写模块端口合一了因为wbu的事情太少了打算直接在寄存时合进来。


ysyx_22050019_WBU WBU(
    .reg_we_exu_lsu_i  ( reg_we_exu_lsu            ),
    .reg_we_lsu_i      ( wen_lsu_reg               ),
    .reg_waddr_exu_i   ( reg_waddr_exu_lsu         ),
    .reg_waddr_lsu_i   ( waddr_lsu_reg             ),
    .reg_wdata_lsu_i   ( wdata_lsu_wb              ),
    .reg_wdata_csr_i   ( wdate_csr_lsu             ),
    .reg_wdata_exu_i   ( wdata_reg_exu_lsu         ),
    .reg_we_wbu_o      ( reg_we_wb                 ),
    .reg_waddr_wbu_o   ( reg_waddr_wb              ),
    .reg_wdata_wbu_o   ( reg_wdata_wb              )
);

assign mem_wb_commit = ex_mem_stall ? 0 : commite_ex_mem|wen_lsu_reg|axi_lsu_sram_b_valid&axi_lsu_sram_b_ready;
ysyx_22050019_MEM_WB MEM_WB(
    .clk              ( clock                       ),
    .rst_n            ( reset                     ),
    .pc_i             ( pc_exu_mem                ),
    .inst_i           ( inst_exu_mem              ),
    .commite_i        ( mem_wb_commit             ),
    .reg_we_wbu_i     ( reg_we_wb                 ),
    .reg_waddr_wbu_i  ( reg_waddr_wb              ),
    .reg_wdata_wbu_i  ( reg_wdata_wb              ),

`ifdef ysyx_22050019_dpic
    .csr_regs_diff_i  ( csr_regs_diff_lsu         ),
    .csr_regs_diff_o  ( csr_regs_diff_wbu         ),
`endif
/* control */
    .mem_wb_stall_i   ( mem_wb_stall              ),

    .pc_o             ( pc                        ),
    .inst_o           ( inst                      ),
    .commite_o        ( commite_mem_wb            ), 
    .reg_we_wbu_o     ( reg_we_wbu                ),
    .reg_waddr_wbu_o  ( reg_waddr_wbu             ),
    .reg_wdata_wbu_o  ( reg_wdata_wbu             )

);

wire stall_raw;
assign stall_raw = (raddr1_id_regs == exu_waddr)&&exu_wen || (raddr1_id_regs == reg_waddr_exu_lsu)&&reg_we_exu_lsu || (raddr1_id_regs == waddr_lsu_reg)&&wen_lsu_reg || (raddr1_id_regs == reg_waddr_wbu)&&reg_we_wbu 
                ||  (raddr2_id_regs == exu_waddr)&&exu_wen || (raddr2_id_regs == reg_waddr_exu_lsu)&&reg_we_exu_lsu || (raddr2_id_regs == waddr_lsu_reg)&&wen_lsu_reg || (raddr2_id_regs == reg_waddr_wbu)&&reg_we_wbu;

//pipeline 总控制器模块
ysyx_22050019_pipeline_Control pipe_control(
    .lsu_stall_req ( lsu_stall_req | fence_stall_dcache ),
    .alu_stall_req ( alu_stall                 ),
    .stall_raw_req ( stall_raw          ),
    .pc_stall_o    ( pc_stall                  ),
    .if_id_stall_o ( if_id_stall               ),
    .id_ex_stall_o ( id_ex_stall               ),
    .ex_mem_stall_o( ex_mem_stall              ),
    .mem_wb_stall_o( mem_wb_stall              )
);

// 解决流水线数据冒险加入的前递单元
//wire [63:0] reg_wen_sel_forwarding =wdata_ex_reg|wdate_csr_exu ;
/*
ysyx_22050019_forwarding forwarding(

    .reg_raddr_1_id      ( raddr1_id_regs             ),
    .reg_raddr_2_id      ( raddr2_id_regs             ),
    .reg_waddr_exu       ( exu_waddr                  ),
    .reg_waddr_lsu       ( reg_waddr_wb               ),
    .reg_wen_exu         ( exu_wen                    ),
    .reg_wen_lsu         ( reg_we_wb                  ),
    .reg_wen_wdata_exu_i ( reg_wen_sel_forwarding     ),
    .reg_wen_wdata_lsu_i ( reg_wdata_wb               ),

    .reg_r_data1_id_i    ( rdata1_id_regs             ),
    .reg_r_data2_id_i    ( rdata2_id_regs             ),
    .forwarding_stall_o  ( forwarding_stall           ),
    .reg_r_data1_id__o   ( rdata1_forwardimg          ),
    .reg_r_data2_id__o   ( rdata2_forwardimg          )
);
*/

//寄存器组端口
ysyx_22050019_regs REGS(
    .clk        (clock                           ),
    .rst_n      (reset),
    .now_pc     (pc                            ),         
    .wdata      (reg_wdata_wbu                 ),
    .waddr      (reg_waddr_wbu                 ),
    .wen        (reg_we_wbu                    ),
`ifdef ysyx_22050019_dpic
    .csr_regs_diff(csr_regs_diff_wbu           ),
`endif
    .raddr1     (raddr1_id_regs                ),
    .raddr2     (raddr2_id_regs                ),
    .rdata1     (rdata1_id_regs                ),
    .rdata2     (rdata2_id_regs                )
);

endmodule
