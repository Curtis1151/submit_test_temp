module ysyx_22050499_MEM (
    input              clock,
    input              reset,
    output     [ 31:0] mem_pc,
    output     [  4:0] mem_Rd,

    input              mem_access_done,
    input      [ 31:0] slave_rdata,    //接受到的读数据
    output     [ 78:0] mem_axi_data,
    input              mem_out_ready,  //下一阶段的准备信号
    input              mem_in_valid,   //上一阶段数据有效信号
    input      [148:0] mem_in_bits,    //上一阶段的数据
    output reg         mem_in_ready,   //当前阶段是否空闲信号
    output             mem_out_valid,  //当前阶段输出数据有效信号
    output     [178:0] mem_out_bits,    //当前阶段输出数据
    input      [31:0]  wb_pc
);

  wire [ 0:0] MemRe       = mem_in_bits [148:148];
  assign      mem_pc      = mem_in_bits [147:116];
  wire [0 :0] fence_i     = mem_in_bits [115 :115];

  //因为mem访存并不是立马传递数据给axi,因此数据需存到mem_out_bits,以免被更改
  wire [31:0] mem_addr    = mem_in_bits [114 :83 ];  //alu_result
  wire [31:0] mem_wdata   = mem_in_bits [82  :51 ];  //rs2_data
  wire [2 :0] MemWidth    = mem_in_bits [50  :48 ];
  wire [2 :0] MemDataSext = mem_in_bits [47  :45 ];
  wire [0 :0] MemWe       = mem_in_bits [44  : 44];  //因为要对该值会有更改，所以直接用的mem_bus_data

  wire [31:0] csrs_out    = mem_in_bits [43  :12 ];
  wire [1 :0] MemtoReg    = mem_in_bits [11  :10 ];
  wire [2 :0] csrs_addr   = mem_in_bits [9   :7  ];
  wire [4 :0] Rd          = mem_in_bits [6   :2  ];
  wire [0 :0] CSRs_We     = mem_in_bits [1   :1  ];
  wire [0 :0] RegWe       = mem_in_bits [0   :0  ];

  assign mem_Rd = Rd;

  //=====================================================================================
  // 与AXI通信的数据
  //=====================================================================================
  wire [3:0] mem_wstrb;  //mask
  assign     mem_wstrb = (MemWidth == 3'h1 ? 4'b0001 :
                         (MemWidth == 3'h2 ? 4'b0011 :
                         (MemWidth == 3'h4 ? 4'b1111 :
                                         4'b0000)));
  wire [2:0] mem_awsize = (MemWidth == 3'b001 ? 3'b000 :  //1字节
                          (MemWidth == 3'b010 ? 3'b001 :
                          (MemWidth == 3'b100 ? 3'b010 :
                                            3'b000)));//64位，这种时候一般不会传输，不用管
  wire [2:0] mem_arsize = (MemDataSext == 3'b001 ? 3'b000 :  //1字节
                          (MemDataSext == 3'b010 ? 3'b000 :  //1字节
                          (MemDataSext == 3'b011 ? 3'b001 :  //2字节
                          (MemDataSext == 3'b100 ? 3'b001 :  //2字节
                                               3'b010))));  //4字节

  reg mem_awvalid;
  reg mem_wvalid;
  reg mem_arvalid;
  wire mem_rready = mem_access_done ? 1'b0 : 1'b1;
  // 这些暂时没有用到
  wire mem_bready = mem_access_done ? 1'b0 : 1'b1;

  wire        ren = (MemtoReg == 2'b1);

  reg  [31:0] rdata;  // master
  wire [31:0] DataOut;

  //=====================================================================================
  // 这里用mem_out_bits的mem_datasext控制信号，防止因新的控制信号传递过来，导
  // 致结果错误。
  //=====================================================================================
  assign DataOut = (MemDataSext == 3'b001 ? {{24{rdata[7]}}, rdata[7  :0]} :  // LB
                   (MemDataSext == 3'b010 ? {{24{1'b0}}, rdata[7      :0]} :  // LBU
                   (MemDataSext == 3'b011 ? {{16{rdata[15]}}, rdata[15:0]} :  // LH
                   (MemDataSext == 3'b100 ? {{16{1'b0}}, rdata[15     :0]} :  // LHU
                                            rdata))));                        // LW
  assign mem_axi_data = {
    mem_arsize,
    mem_awsize,
    mem_arvalid,
    mem_rready,
    mem_addr,
    mem_awvalid,
    mem_wdata,
    mem_wstrb,
    mem_wvalid,
    mem_bready
  };

  assign mem_out_bits = {
    DataOut,       // bus[178,147]
    mem_pc,        // bus[146:115]
    mem_in_bits[114:0]
  };



  //=====================================================================================
  // 流水级信号
  //=====================================================================================

  assign mem_out_valid = ((state == STATE_NO_LS) || (state == STATE_SEND_DATA)) && mem_out_valid_t && (mem_pc != wb_pc);
  reg mem_out_valid_t;

  // mem_out_valid 更新逻辑
  always @(posedge clock) begin
    if (reset) begin
      mem_out_valid_t <= 0;
    end else begin
      if (mem_in_ready & mem_in_valid) begin
        mem_out_valid_t <= 1;
      end else if (mem_out_valid & mem_out_ready) begin
        mem_out_valid_t <= 0;
      end else begin
        mem_out_valid_t <= mem_out_valid_t;
      end
    end
  end

  // mem_in_ready 更新逻辑

  always @(posedge clock) begin
    if (reset) begin
      mem_in_ready <= 1; //初始化时为空闲状态
    end else begin

      //----------------------------------------------------------
      // 当前阶段: 空闲与忙碌状态的切换逻辑
      //----------------------------------------------------------
      if (mem_in_ready) begin
        /* 空闲状态唯有等上一阶段输出有效时，才能切换至忙碌状态*/
        if (mem_in_valid) begin
          mem_in_ready <= 0; //由于WB忙碌，故mem进入忙碌状态
        end
      end else begin
        /* 忙碌状态: 唯有下一阶段空闲时，才能切换至空闲状态*/
        if (state == STATE_NO_LS || state == STATE_SEND_DATA) begin
          mem_in_ready <= 1'b1;
        end
      end
    end
  end


  //=====================================================================================
  // AXI通信状态机
  //=====================================================================================

  localparam STATE_IDLE = 4'h0;
  localparam STATE_START_LS = 4'h1;
  localparam STATE_SEND_DATA = 4'h2;
  localparam STATE_NO_LS = 4'h3;

  reg [3:0] state;
  always @(posedge clock) begin
    if (reset) begin
    end else begin
      case (state)
        //----------------------------------------------------------
        // STATE_IDLE: if处于忙碌状态时,才能进行axi通信
        //----------------------------------------------------------
        STATE_IDLE: begin
          if (~mem_in_ready) begin
            if (MemWe) begin
              state <= STATE_START_LS;
              mem_awvalid <= 1'b1;
              mem_wvalid  <= 1'b1;
            end else if (MemRe) begin
              state <= STATE_START_LS;
              mem_arvalid <= 1'b1;
            end else begin
              state <= STATE_NO_LS;
            end
          end
        end
        //----------------------------------------------------------
        // STATE_START_LS
        //----------------------------------------------------------
        STATE_START_LS: begin
          if (mem_access_done) begin
            mem_arvalid <= 1'b0;
            mem_awvalid <= 1'b0;
            mem_wvalid  <= 1'b0;
            state <= STATE_SEND_DATA;
            rdata <= slave_rdata;
          end
        end
        //-----------------------------------------------------------------
        // STATE_SEND_DATA: 等待下一阶段ok,然后再切换到idle状态
        //-----------------------------------------------------------------
        STATE_SEND_DATA: begin
          //如果是读，这里需要将最新的dataout传下去
          if (mem_out_ready) begin
            state <= STATE_IDLE;
          end
        end
        //-----------------------------------------------------------------
        // STATE_NO_LS: 等待下一阶段ok,然后再切换到idle状态
        //-----------------------------------------------------------------
        STATE_NO_LS: begin
          if (mem_out_ready) begin
            state <= STATE_IDLE;
          end
        end
        default: begin
        end
      endcase
    end
  end

endmodule

