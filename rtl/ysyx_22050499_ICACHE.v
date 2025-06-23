`include "macros.vh"
module ysyx_22050499_ICACHE (
    input clock,
    input reset,
    input fence_i,
    input check_icache,
    input [31:0] raddr,
    input [127:0] sdram_rdata,
    input         sdram_read_ok,
    output     [31:0] icache_rdata,
    output reg icache_ok,
    output     icache_hit
);

  //=====================================================================================
  // I-Cache 参数: 规定了大小，可以根据ICACHE_LINE_SIZE调节各个参数
  // 64bit, 1 Way, 16 Line,  1Line = 4B
  //=====================================================================================
  parameter ICACHE_SIZE       = 64;                              //ICACHE 的总大小,单位为Byte
  parameter ICACHE_INST_NUM   = 16;                              //ICACHE 的指令的总数量


  parameter ICACHE_WAY        = 1;                               //暂时不采用组相联，故暂时用不到
  parameter ICACHE_LINE_SIZE  = 4 * (2**m);                      //块大小，单位Byte
  parameter ICACHE_LINE_COUNT = ICACHE_SIZE / ICACHE_LINE_SIZE;  // 块数量

  parameter m = 0;// ICACHE_LINE_SIZE  = 4* (2**m),一个块可以存多少条指令的log2
  parameter n = 4;// ICACHE_LINE_COUNT = 2**n;

  /* 随时根据m的值来注释或不注释,m = 0时注释 */
  //`define M_THAN_0 1

  //=====================================================================================
  // I-Cache 地址编码             [31    : 2    ] 适用于m >= 1
  // tag   : 对应数据的唯一标识符,[31    : m+n+2]
  // index : 块的索引号,          [m+n+1 : m+2  ]
  // offset: 块中的偏移量,        [m+1   : 2    ]
  //
  // icache[index,offset] =  inst,不过要对上tag才有效
  //=====================================================================================

  reg [        31:0]   Icache       [0 : ICACHE_INST_NUM-1];
  reg [31-(m+n+2) : 0] Icache_tag   [0 : ICACHE_LINE_COUNT-1];
  reg                  Icache_valid [0 : ICACHE_LINE_COUNT-1];

  // icache值的复位
  integer i;
  always @(posedge clock) begin
    if (reset || fence_i) begin
      // 对 Icache 数组进行复位
      for (i = 0; i < ICACHE_INST_NUM; i = i + 1) begin
        Icache[i]     <= 32'b0;  // 将每个 Icache 寄存器清零
      end
      // 对 Icache_valid 数组进行复位
      for (i = 0; i < ICACHE_LINE_COUNT; i = i + 1) begin
        Icache_valid[i] <= 1'b0;  // 将每个 Icache_valid 寄存器清零
        Icache_tag[i] <= 0;  // 将每个 Icache_tag 寄存器清零
      end
    end else begin
    end
  end

  //=====================================================================================
  // Icache 命中判断
  //=====================================================================================


  wire [29-(m+n) : 0] tag    = raddr[31    : m+n+2];
  wire [n-1      : 0] index  = raddr[m+n+1 : m+2];
  `ifdef M_THAN_0
  wire [m-1      : 0] offset = raddr[m+1   : 2  ];
  `endif

  wire [31:0] addr1 = raddr + 4;
  wire [31:0] addr2 = raddr + 8;
  wire [31:0] addr3 = raddr + 12;
  wire [29-(m+n) : 0] tag1 = addr1[31: m+n+2];
  wire [29-(m+n) : 0] tag2 = addr2[31: m+n+2];
  wire [29-(m+n) : 0] tag3 = addr3[31: m+n+2];
  wire [n-1      : 0] index1  = addr1[m+n+1 : m+2];
  wire [n-1      : 0] index2  = addr2[m+n+1 : m+2];
  wire [n-1      : 0] index3  = addr3[m+n+1 : m+2];

  `ifdef M_THAN_0
    assign icache_rdata = Icache[{index,offset}];
  `else
    assign icache_rdata = Icache[{index}];
  `endif
  assign icache_hit = (Icache_valid[index] == 1) && (Icache_tag[index] == tag);

  always @(posedge clock) begin
    if (check_icache) begin
      if (sdram_read_ok) begin
        icache_ok                   <= 1'b1;
        Icache_valid[index ]     <= 1;
        Icache_valid[index1]     <= 1;
        Icache_valid[index2]     <= 1;
        Icache_valid[index3]     <= 1;
        Icache      [index ]     <= sdram_rdata[127:96];
        Icache      [index1]     <= sdram_rdata[95 :64];
        Icache      [index2]     <= sdram_rdata[63 :32];
        Icache      [index3]     <= sdram_rdata[31 :0];
        Icache_tag  [index ]     <= tag;
        Icache_tag  [index1]     <= tag1;
        Icache_tag  [index2]     <= tag2;
        Icache_tag  [index3]     <= tag3;
      end
    end else begin
      icache_ok <= 1'b0;
    end
  end

endmodule
