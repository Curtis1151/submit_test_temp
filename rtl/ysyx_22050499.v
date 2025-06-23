`include "macros.vh"
`ifdef CONFIG_STA_MODE
import "DPI-C" function void update_perf_counter(input int tags);
import "DPI-C" function void npc_update_pc(input int addr);
`endif
module ysyx_22050499 (
    input clock,
    input reset,
    input io_interrupt,

    // Master AW channel
    input         io_master_awready,
    output        io_master_awvalid,
    output [31:0] io_master_awaddr,
    output [ 3:0] io_master_awid,
    output [ 7:0] io_master_awlen,
    output [ 2:0] io_master_awsize,
    output [ 1:0] io_master_awburst,

    // Slave AW channel
    output        io_slave_awready,
    input         io_slave_awvalid,
    input  [31:0] io_slave_awaddr,
    input  [ 3:0] io_slave_awid,
    input  [ 7:0] io_slave_awlen,
    input  [ 2:0] io_slave_awsize,
    input  [ 1:0] io_slave_awburst,

    // Master W channel
    input         io_master_wready,
    output        io_master_wvalid,
    output [31:0] io_master_wdata,
    output [ 3:0] io_master_wstrb,
    output        io_master_wlast,

    // Slave W channel
    output        io_slave_wready,
    input         io_slave_wvalid,
    input  [31:0] io_slave_wdata,
    input  [ 3:0] io_slave_wstrb,
    input         io_slave_wlast,

    // Master B channel
    output       io_master_bready,
    input        io_master_bvalid,
    input  [1:0] io_master_bresp,
    input  [3:0] io_master_bid,

    // Slave B channel
    input        io_slave_bready,
    output       io_slave_bvalid,
    output [1:0] io_slave_bresp,
    output [3:0] io_slave_bid,

    // Master AR channel
    input             io_master_arready,
    output reg        io_master_arvalid,
    output     [31:0] io_master_araddr,
    output     [ 3:0] io_master_arid,
    output     [ 7:0] io_master_arlen,
    output     [ 2:0] io_master_arsize,
    output     [ 1:0] io_master_arburst,

    // Slave AR channel
    output        io_slave_arready,
    input         io_slave_arvalid,
    input  [31:0] io_slave_araddr,
    input  [ 3:0] io_slave_arid,
    input  [ 7:0] io_slave_arlen,
    input  [ 2:0] io_slave_arsize,
    input  [ 1:0] io_slave_arburst,

    // Master R channel
    output        io_master_rready,
    input         io_master_rvalid,
    input  [ 1:0] io_master_rresp,
    input  [31:0] io_master_rdata,
    input         io_master_rlast,
    input  [ 3:0] io_master_rid,

    // Slave R channel
    input         io_slave_rready,
    output        io_slave_rvalid,
    output [ 1:0] io_slave_rresp,
    output [31:0] io_slave_rdata,
    output        io_slave_rlast,
    output [ 3:0] io_slave_rid
);

  wire [120:0] o_master_axi_data;
  assign io_master_arburst = o_master_axi_data[120:119];
  assign io_master_arlen   = o_master_axi_data[118:111];
  assign io_master_araddr  = o_master_axi_data[110:79];
  assign io_master_arsize  = o_master_axi_data[78:76];
  assign io_master_awsize  = o_master_axi_data[75:73];
  assign io_master_arvalid = o_master_axi_data[72];
  assign io_master_rready  = o_master_axi_data[71];
  assign io_master_awaddr  = o_master_axi_data[70:39];
  assign io_master_awvalid = o_master_axi_data[38];
  assign io_master_wdata   = o_master_axi_data[37:6];
  assign io_master_wstrb   = o_master_axi_data[5:2];
  assign io_master_wvalid  = o_master_axi_data[1];
  assign io_master_bready  = o_master_axi_data[0];

  //没有写突发，所以在穿过去wdata后，立马结束
  assign io_master_wlast   = io_master_wvalid;

  //slave输入到axi与master的通信信号

  /*================================================*/
  /* ================ 无用信号赋值0 ===========*/
  /*================================================*/
  // Master AW channel
  assign io_master_awid    = 0;
  assign io_master_awburst = 0;
  assign io_master_awlen   = 0;

  // Slave AW channel
  assign io_slave_awready  = 0;

  // Master W channel

  // Slave W channel
  assign io_slave_wready   = 0;

  // Slave B channel
  assign io_slave_bvalid   = 0;
  assign io_slave_bresp    = 0;
  assign io_slave_bid      = 0;

  // Master AR channel
  assign io_master_arid    = 0;

  // Slave AR channel
  assign io_slave_arready  = 0;

  // Slave R channel
  assign io_slave_rvalid   = 0;
  assign io_slave_rresp    = 0;
  assign io_slave_rdata    = 0;
  assign io_slave_rlast    = 0;
  assign io_slave_rid      = 0;
  /*===================end======================*/





  //=====================================================================================
  // IFU阶段的流水级信号
  //=====================================================================================
  wire [31:0] if_pc;
  wire        if_access_done;
  wire        if_out_ready = id_in_ready;       //下一阶段准备好信号

  wire        if_in_ready;                      //当前阶段是否空闲信号
  wire        if_in_valid  = wb_out_valid;      //当前阶段输入数据有效信号
  wire [9 :0] if_in_bits   = wb_out_bits[9:0];  //当前阶段输入数据

  wire [63:0] if_out_bits;
  wire        if_out_valid;                     //当前阶段输出数据有效信号
  wire [33:0] if_axi_data;                      //if与axi总线通信数据


  /* icache 与 axi交互的信号 */
  wire icache_ok;
  wire [127:0] sdram_rdata;
  wire sdram_read_ok;

  ysyx_22050499_IFU ysyx_22050499_IFU (
    .clock                  (clock                         ),
    .reset                  (reset                         ),
    .rdata                  (rdata                         ),
    .if_pc                  (if_pc                         ),
    .ex_dnpc                (ex_dnpc                       ),
    .predict_wrong          (predict_wrong                 ),
    .icache_ok              (icache_ok                     ),
    .sdram_read_ok          (sdram_read_ok                 ),
    .sdram_rdata            (sdram_rdata                   ),
    .fence_i                (fence_i                       ),
    .if_access_done         (if_access_done                ),  //后期可考虑换成if_rvalid不过再说
    .if_axi_data            (if_axi_data                   ),
    .if_out_ready           (if_out_ready                  ),  //下一阶段的准备信号
    .if_in_valid            (if_in_valid                   ),  //上一阶段数据有效信号
    .if_in_bits             (if_in_bits                    ),  //上一阶段的数据,初始化时默认wb阶段的输出pc为pc+4
    .id_in_bits             (id_in_bits                    ),
    .if_in_ready            (if_in_ready                   ),  //当前阶段是否空闲信号
    .if_out_valid           (if_out_valid                  ),  //当前阶段输出数据有效信号
    .if_out_bits            (if_out_bits                   )  //当前阶段输出数据
  );


  //=====================================================================================
  // IF-ID 流水级间寄存器
  // !!!ID不会得到错误的PC值
  //=====================================================================================
  always @(posedge clock) begin
    if (if_out_valid && if_out_ready) begin
      id_in_bits <= if_out_bits;
    end
  end

  //=====================================================================================
  // IDU阶段的流水级信号
  //=====================================================================================
  wire [31 :0] id_pc;

  wire         id_in_ready;                 //当前阶段是否空闲信号
  wire         id_in_valid  = if_out_valid; //当前阶段输入数据有效信号
  reg  [63 :0] id_in_bits;                  //当前阶段输入数据

  wire [208:0] id_out_bits;                 //当前阶段输出数据
  wire         id_out_ready = ex_in_ready;  //下一阶段准备好信号
  wire         id_out_valid;                //当前阶段输出数据有效信号

  wire         raw_handle;

  ysyx_22050499_IDU ysyx_22050499_IDU (
    .clock                 (clock                 ),
    .reset                 (reset                 ),
    .id_pc                 (id_pc                 ),
    .wb_pc                 (wb_pc                 ),
    .mem_pc                (mem_pc                 ),
    .ex_pc                 (ex_pc                 ),

    .wb_Rd                 (wb_Rd                 ),
    .ex_Rd                 (ex_Rd                 ),
    .mem_Rd                (mem_Rd                ),

    .ex_dnpc               (ex_dnpc               ),
    .predict_wrong         (predict_wrong         ),

    .ex_in_ready           (ex_in_ready           ),
    .mem_in_ready          (mem_in_ready          ),
    .wb_in_ready           (~wb_out_valid         ), //wb阶段的特殊性，用wb_out_valid当作ready

    .wb_RegWe              (wb_RegWe              ),
    .wb_CSRs_We            (wb_CSRs_We            ),
    .wb_reg_waddr          (wb_reg_waddr          ),
    .wb_csrs_waddr         (wb_csrs_waddr         ),
    .wb_reg_DataIn         (reg_write_data        ),
    .wb_csrs_wdata         (csrs_wdata            ),
    .id_out_ready          (id_out_ready          ),  //下一阶段的准备信号
    .id_in_valid           (id_in_valid           ),  //上一阶段数据有效信号
    .id_in_bits            (id_in_bits            ),  //上一阶段的数据
    .id_in_ready           (id_in_ready           ),  //当前阶段是否空闲信号
    .id_out_valid          (id_out_valid          ),  //当前阶段输出数据有效信号
    .id_out_bits           (id_out_bits           ),  //当前阶段输出数据
    .raw_handle(raw_handle)
  );


  //=====================================================================================
  // ID-EX 流水级间寄存器
  //=====================================================================================
  always @(posedge clock) begin
    if (id_out_valid && id_out_ready) begin
      ex_in_bits <= id_out_bits;
    end
  end

  //=====================================================================================
  //EXU阶段的流水级信号
  //=====================================================================================
  wire [31 :0] ex_pc;
  wire         ex_out_ready = mem_in_ready;//下一阶段准备好信号
  wire         ex_in_valid  = id_out_valid;//当前阶段输入数据有效信号
  reg  [208:0] ex_in_bits;                 //当前阶段输入数据
  wire [148:0] ex_out_bits;                //当前阶段输出数据
  wire         ex_in_ready;                //当前阶段是否空闲信号
  wire         ex_out_valid;               //当前阶段输出数据有效信号

  /*  其他信号  */
  wire         fence_i      = ex_out_bits[115];
  wire [4:0] ex_Rd;

  wire [31 :0] ex_dnpc;
  wire         predict_wrong;

  ysyx_22050499_EXU ysyx_22050499_EXU (
    .clock                (clock                ),
    .reset                (reset                ),
    .ex_pc                (ex_pc                ),
    .ex_Rd                (ex_Rd                ),
    .mem_pc               (mem_pc               ),
    .ex_dnpc              (ex_dnpc              ),
    .predict_wrong        (predict_wrong        ),
    .ex_out_ready         (ex_out_ready         ),  //下一阶段的准备信号
    .ex_in_valid          (ex_in_valid          ),  //上一阶段数据有效信号
    .ex_in_bits           (ex_in_bits           ),  //上一阶段的数据
    .ex_in_ready          (ex_in_ready          ),  //当前阶段是否空闲信号
    .ex_out_valid         (ex_out_valid         ),  //当前阶段输出数据有效信号
    .ex_out_bits          (ex_out_bits          )   //当前阶段输出数据
  );

  //=====================================================================================
  // EX-MEM 流水级间寄存器
  //=====================================================================================
  always @(posedge clock) begin
    if (ex_out_valid && ex_out_ready) begin
      mem_in_bits <= ex_out_bits;
    end
  end

  //=====================================================================================
  // MEM阶段的流水级信号
  //=====================================================================================
  wire [31 :0] mem_pc;
  wire         mem_out_ready = wb_in_ready; //下一阶段准备好信号
  wire         mem_in_valid  = ex_out_valid;//当前阶段输入数据有效信号
  reg  [148:0] mem_in_bits;                 //当前阶段输入数据
  wire [178:0] mem_out_bits;                //当前阶段输出数据
  wire         mem_in_ready;                //当前阶段是否空闲信号
  wire         mem_out_valid;               //当前阶段输出数据有效信号
  /*   总线信号 */
  wire [ 78:0] mem_axi_data;
  wire         mem_access_done;

  wire [ 4:0]  mem_Rd;

  ysyx_22050499_MEM ysyx_22050499_MEM (
    .clock           (clock          ),
    .reset           (reset          ),
    .mem_access_done (mem_access_done),
    .mem_pc          (mem_pc         ),
    .wb_pc           (wb_pc          ),
    .mem_Rd          (mem_Rd         ),
    .slave_rdata     (rdata          ),
    .mem_axi_data    (mem_axi_data   ),
    .mem_out_ready   (mem_out_ready  ),  //下一阶段的准备信号
    .mem_in_valid    (mem_in_valid   ),  //上一阶段数据有效信号
    .mem_in_bits     (mem_in_bits    ),  //上一阶段的数据
    .mem_in_ready    (mem_in_ready   ),  //当前阶段是否空闲信号
    .mem_out_valid   (mem_out_valid  ),  //当前阶段输出数据有效信号
    .mem_out_bits    (mem_out_bits   )  //当前阶段输出数据
  );

  //=====================================================================================
  // MEM-WB 流水级间寄存器
  //=====================================================================================
  always @(posedge clock) begin
    if (mem_out_valid && mem_out_ready) begin
      wb_in_bits <= mem_out_bits;
      `ifdef CONFIG_STA_MODE
      npc_update_pc(mem_out_bits[146:115]);
      `endif
    end
  end

  //=====================================================================================
  // WB阶段的流水级信号
  //=====================================================================================
  wire [31 :0]  wb_pc;
  wire         wb_out_ready = if_in_ready; //下一阶段准备好信号
  wire         wb_in_valid = mem_out_valid;//当前阶段输入数据有效信号
  reg  [178:0] wb_in_bits;               //当前阶段输入数据
  wire [9  :0] wb_out_bits;//当前阶段输出数据
  wire         wb_in_ready;//当前阶段是否空闲信号
  wire         wb_out_valid;//当前阶段输出数据有效信号

  wire [4:0]   wb_Rd;

  //-------------------------------------------------------------------------------------
  //写回阶段相关控制信号及写数据: 只持续一个周期
  //-------------------------------------------------------------------------------------
  wire [2:0] wb_csrs_waddr = wb_in_bits[9:7] & {3{wb_out_valid}};
  wire [4:0] wb_reg_waddr  = wb_in_bits[6:2] & {5{wb_out_valid}};
  wire [0:0] wb_CSRs_We    = wb_in_bits[1:1] & {1{wb_out_valid}};
  wire [0:0] wb_RegWe      = wb_in_bits[0:0] & {1{wb_out_valid}};

  /*     其他信号  */
  wire [31 :0] reg_write_data;
  wire [31 :0] csrs_wdata;

  ysyx_22050499_WB ysyx_22050499_WB (
    .clock          (clock         ),
    .reset          (reset         ),
    .wb_pc          (wb_pc         ),
    .wb_Rd          (wb_Rd         ),
    .reg_write_data (reg_write_data),
    .csrs_wdata     (csrs_wdata    ),
    .wb_out_ready   (wb_out_ready  ),  //下一阶段的准备信号
    .wb_in_valid    (wb_in_valid   ),  //上一阶段数据有效信号
    .wb_in_bits     (wb_in_bits    ),  //上一阶段的数据
    .wb_in_ready    (wb_in_ready   ),  //当前阶段是否空闲信号
    .wb_out_valid   (wb_out_valid  ),  //当前阶段输出数据有效信号
    .wb_out_bits    (wb_out_bits   )   //当前阶段输出数据
  );


  //=====================================================================================
  // AXI4总线通信模块
  //=====================================================================================
  reg  [31:0] rdata; //重要，axi输出到IFU,MEM

  ysyx_22050499_AXI_BUS ysyx_22050499_AXI (
      .clock            (clock            ),
      .reset            (reset            ),
      .if_axi_data      (if_axi_data      ),
      .mem_axi_data     (mem_axi_data     ),
      .rdata            (rdata            ),
      .if_access_done   (if_access_done   ),
      .mem_access_done  (mem_access_done  ),
      .fence_i          (fence_i          ),
      .icache_ok        (icache_ok        ),
      .sdram_read_ok    (sdram_read_ok    ),
      .sdram_rdata      (sdram_rdata      ),
      .io_master_rvalid (io_master_rvalid ),
      .io_master_rresp  (io_master_rresp  ),
      .io_master_rdata  (io_master_rdata  ),
      .io_master_rlast  (io_master_rlast  ),
      .io_master_awready(io_master_awready),
      .io_master_wready (io_master_wready ),
      .io_master_bvalid (io_master_bvalid ),
      .io_master_bresp  (io_master_bresp  ),
      .io_master_bid    (io_master_bid    ),
      .io_master_arready(io_master_arready),
      .o_master_axi_data(o_master_axi_data)
  );


endmodule
