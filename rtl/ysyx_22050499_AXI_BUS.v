`include "macros.vh"
`ifdef CONFIG_STA_MODE
import "DPI-C" function void npc_assert(input int addr);
`endif

// resp不同值的含义
`define OKAY 2'b00
`define EXOKAY 2'b01
`define SLVERR 2'b10
`define DECERR 2'b11
/********end**********/

module ysyx_22050499_AXI_BUS (
    input              clock,
    input              reset,
    input      [ 33:0] if_axi_data,
    input      [78:0]  mem_axi_data,
    input              io_master_rlast,
    input              io_master_rvalid,
    input      [  1:0] io_master_rresp,
    input      [ 31:0] io_master_rdata,
    input              io_master_awready,
    input              io_master_wready,
    input              io_master_bvalid,
    input      [  1:0] io_master_bresp,
    input      [  3:0] io_master_bid,
    input              io_master_arready,
    input              fence_i,
    output reg         if_access_done,
    output reg         mem_access_done,
    output reg [ 31:0] rdata,              //传送给主机的
    output reg [120:0] o_master_axi_data,
    /* 与icache ifu 交互 */
    input              icache_ok,
    output reg [127:0] sdram_rdata,
    output reg         sdram_read_ok

);

  parameter s_idle = 3'h0;  //空闲状态
  parameter s_1    = 3'h1;  // 成功实现AW通信，准备W通信
  parameter s_2    = 3'h2;  // 成功W通信，准备B通信。 通信成功则回到idle
  parameter s_3    = 3'h3;  // 成功实现AR通信，准备R通信,通信成功回到idle
  parameter s_4    = 3'h5;  // 成功读sdram,等icache完成写入相关操作
  parameter s_0    = 3'h4; // 成功传递数据
  reg [2:0] s_states;


  `define IO_MASTER_ARBURST o_master_axi_data[120:119]
  `define IO_MASTER_ARLEN   o_master_axi_data[118:111]
  `define IO_MASTER_ARADDR  o_master_axi_data[110:79]
  `define IO_MASTER_ARADDR  o_master_axi_data[110:79]
  `define IO_MASTER_ARSIZE  o_master_axi_data[78:76]
  `define IO_MASTER_AWSIZE  o_master_axi_data[75:73]
  `define IO_MASTER_ARVALID o_master_axi_data[72]
  `define IO_MASTER_RREADY  o_master_axi_data[71]
  `define IO_MASTER_AWADDR  o_master_axi_data[70:39]
  `define IO_MASTER_AWVALID o_master_axi_data[38]
  `define IO_MASTER_WDATA   o_master_axi_data[37:6]
  `define IO_MASTER_WSTRB   o_master_axi_data[5:2]
  `define IO_MASTER_WVALID  o_master_axi_data[1]
  `define IO_MASTER_BREADY  o_master_axi_data[0]


  `define MEM_ARSIZE  mem_axi_data[78:76]
  `define MEM_AWSIZE  mem_axi_data[75:73]
  `define MEM_ARVALID mem_axi_data[72]
  `define MEM_RREADY  mem_axi_data[71]
  `define MEM_ADDR    mem_axi_data[70:39]
  `define MEM_AWVALID mem_axi_data[38]
  `define MEM_WDATA   mem_axi_data [37:6]
  `define MEM_WSTRB   mem_axi_data[5:2]
  `define MEM_WVALID  mem_axi_data[1]
  `define MEM_BREADY  mem_axi_data[0]

  `define IFU_ADDR    if_axi_data[33:2]
  `define IFU_ARVALID if_axi_data[1]
  `define IFU_RREADY  if_axi_data[0]

  //=====================================================================================
  // AXI仲裁器
  //=====================================================================================
  wire is_fetch = `IFU_ARVALID && ~if_access_done;
  wire is_read  = `MEM_ARVALID && ~mem_access_done;
  wire is_write = `MEM_AWVALID && ~mem_access_done;

  wire happen_conflict = (is_fetch && (is_read || is_write)) && ~axi_actived;
  localparam CONFLICT_STATE_IDLE = 2'b00;
  localparam CONFLICT_STATE_IFU = 2'b01;
  localparam CONFLICT_STATE_LSU = 2'b10;
  localparam CONFLICT_STATE_WAIT = 2'b11;
  reg [1:0] conflict_state;
  reg axi_actived;

  always @(posedge clock) begin
    if (~happen_conflict) begin
      if (write_mode || read_mode || fetch_mode) begin
        axi_actived <= 1'b1;
      end else begin
        axi_actived <= 1'b0;
      end
    end
  end
  always @(posedge clock) begin
    if (reset) begin
      conflict_state <= CONFLICT_STATE_IDLE;
    end else begin
      if (conflict_state == CONFLICT_STATE_IDLE) begin
        if (happen_conflict) begin
          conflict_state <= CONFLICT_STATE_IFU;
        end

      end else if (conflict_state == CONFLICT_STATE_IFU) begin
        if (if_access_done) begin
          conflict_state <= CONFLICT_STATE_LSU;
        end

      end else if (conflict_state == CONFLICT_STATE_LSU) begin
        if (mem_access_done) begin
          conflict_state <= CONFLICT_STATE_WAIT;
        end

      end else if (conflict_state == CONFLICT_STATE_WAIT) begin
        if (~happen_conflict) begin
          conflict_state <= CONFLICT_STATE_IDLE;
        end
      end
    end
  end

  //=====================================================================================
  // XBAR-译码器: 根据地址译码
  //=====================================================================================
  wire xbarDecodeStart = is_fetch || is_read || is_write;
  reg  [3:0] xbar_decode;//在通信开始时赋值，结束时为0
  wire [3:0] xbar_decode_t  =
    (xbarDecodeStart) ?
      ((is_read || is_write)&&(~mem_access_done)&&(~happen_conflict ||  (conflict_state == CONFLICT_STATE_LSU)) ? /* 没发生冲突或发生冲突但已解决时*/
        ((`MEM_ADDR >= 32'h2000_0000 && `MEM_ADDR < 32'h2000_1000) ? 4'b0010 : /*MROM*/
         (`MEM_ADDR >= 32'h0200_0000 && `MEM_ADDR < 32'h0201_0000) ? 4'b0001 : /*CLINT*/
         (`MEM_ADDR >= 32'h1000_0000 && `MEM_ADDR < 32'h1000_1000) ? 4'b0011 : /*UART*/
         (`MEM_ADDR >= 32'h0f00_0000 && `MEM_ADDR < 32'h0f00_2000) ? 4'b0100 : /*SRAM*/
         (`MEM_ADDR >= 32'h3000_0000 && `MEM_ADDR < 32'h4000_0000) ? 4'b0101 : /*XIP to flash */
         (`MEM_ADDR >= 32'h1000_1000 && `MEM_ADDR < 32'h1000_2000) ? 4'b0110 : /*SPI*/
         (`MEM_ADDR >= 32'h8000_0000 && `MEM_ADDR < 32'h9000_0000) ? 4'b0111 : /*PSRAM*/
         (`MEM_ADDR >= 32'ha000_0000 && `MEM_ADDR < 32'hc000_0000) ? 4'b1000 : /*SDRAM*/
         (`MEM_ADDR >= 32'h1001_1000 && `MEM_ADDR < 32'h1001_1008) ? 4'b1001 : /*PS2*/
         (`MEM_ADDR >= 32'h2100_0000 && `MEM_ADDR < 32'h2120_0000) ? 4'b1010 : /*VGA*/
                                                                    4'b0000) :
      (is_fetch && (~if_access_done) ?
        ((`IFU_ADDR >= 32'h2000_0000 && `IFU_ADDR < 32'h2000_1000) ? 4'b0010 : /*MROM*/
         (`IFU_ADDR >= 32'h0f00_0000 && `IFU_ADDR < 32'h0f00_2000) ? 4'b0100 : /*SRAM*/
         (`IFU_ADDR >= 32'h3000_0000 && `IFU_ADDR < 32'h4000_0000) ? 4'b0101 : /*XIP to flash */
         (`IFU_ADDR >= 32'h8000_0000 && `IFU_ADDR < 32'h9000_0000) ? 4'b0111 : /*PSRAM*/
         (`IFU_ADDR >= 32'ha000_0000 && `IFU_ADDR < 32'hc000_0000) ? 4'b1111 : /*SDRAM special */
                                                                    4'b0000) :
         4'b0000)
    ) : 4'b0000;



  //=====================================================================================
  //  delay模块，维持access  1个周期有效
  //=====================================================================================
  reg [1:0] counter;
  always @(posedge clock) begin
    if (reset) begin
      counter <= 2'b0;
    end else if (if_access_done || mem_access_done) begin //维持access_done 2周期
      if_access_done <= 1'b0;
      mem_access_done <= 1'b0;
    end
  end

  //=====================================================================================
  // 传递数据给对应通信,并切换状态至s_0
  // 传递译码信号给xbar_decode,确定通信模式
  //=====================================================================================
  reg fetch_mode;
  reg read_mode;
  reg write_mode;
  always @(posedge clock) begin
    if (reset) begin
      s_states <= s_idle;
      xbar_decode <= 4'b0;
    end else begin
      if (s_states <= s_idle) begin
        if (is_write && (~happen_conflict || (conflict_state == CONFLICT_STATE_LSU))) begin
          xbar_decode <= xbar_decode_t;
          write_mode <= 1;
          // B通道
          `IO_MASTER_BREADY  <= `MEM_BREADY;
          //AW通道
          `IO_MASTER_AWVALID <= 0;
          `IO_MASTER_AWADDR  <= `MEM_ADDR;
          `IO_MASTER_AWSIZE  <= `MEM_AWSIZE;
          //W通道
          `IO_MASTER_WVALID  <= 0;
          case (`MEM_ADDR & 32'b11)
            32'h0: begin
              `IO_MASTER_WSTRB <= `MEM_WSTRB << 0;
              `IO_MASTER_WDATA <= `MEM_WDATA << 0;
            end
            32'h1: begin
              `IO_MASTER_WSTRB <= `MEM_WSTRB << 1;
              `IO_MASTER_WDATA <= `MEM_WDATA << 8;
            end
            32'h2: begin
              `IO_MASTER_WSTRB <= `MEM_WSTRB << 2;
              `IO_MASTER_WDATA <= `MEM_WDATA << 16;
            end
            32'h3: begin
              `IO_MASTER_WSTRB <= `MEM_WSTRB << 3;
              `IO_MASTER_WDATA <= `MEM_WDATA << 24;
            end
          endcase
          s_states <= s_0;
        end else if (is_read && (~happen_conflict || (conflict_state == CONFLICT_STATE_LSU))) begin
          read_mode <= 1'b1;
          xbar_decode <= xbar_decode_t;
          //R通道
          `IO_MASTER_RREADY  <= `MEM_RREADY;
          //AR通道
          `IO_MASTER_ARVALID <= 0;
          `IO_MASTER_ARADDR  <= `MEM_ADDR;
          `IO_MASTER_ARSIZE  <= `MEM_ARSIZE;
          `IO_MASTER_ARBURST <= 2'b0;
          `IO_MASTER_ARLEN   <= 8'b0;
          s_states <= s_0;
        end else if (is_fetch && (~happen_conflict || (conflict_state == CONFLICT_STATE_IFU))) begin
          fetch_mode <= 1'b1;
          xbar_decode <= xbar_decode_t;
          //R通道
          `IO_MASTER_RREADY  <= `IFU_RREADY;
          //AR通道
          `IO_MASTER_ARVALID <= 0;
          `IO_MASTER_ARADDR  <= `IFU_ADDR;
          `IO_MASTER_ARSIZE  <= 3'b010;
          s_states           <= s_0;
          `IO_MASTER_ARBURST <= 2'b0;
          `IO_MASTER_ARLEN   <= 8'b0;
        end else begin
          s_states <= s_states;
        end
      end
    end
  end



  //=====================================================================================
  // AXI总线通信
  // `access_done`: 通信完成信号,传递给IFU,MEM环节
  // 通信结束时，xbar_decode <= 0
  //=====================================================================================
  always @(posedge clock) begin
    if (reset) begin
      if_access_done <= 1'b0;
      mem_access_done <= 1'b0;
    end else begin
      if (xbar_decode == 4'b0010 || xbar_decode == 4'b0011 ||
          xbar_decode == 4'b0110 || xbar_decode == 4'b0101 ||
          xbar_decode == 4'b1001 || xbar_decode == 4'b1010 ||
          xbar_decode == 4'b0100 || xbar_decode == 4'b0111 ||
          xbar_decode == 4'b1000) begin
        if (s_states == s_0) begin
          if (`IO_MASTER_AWVALID && io_master_awready &&
              `IO_MASTER_WVALID  && io_master_wready) begin
            `IO_MASTER_AWVALID <= 1'b0;
            `IO_MASTER_WVALID <= 1'b0;
            s_states <= s_2;
          end else if (`IO_MASTER_ARVALID & io_master_arready) begin
            `IO_MASTER_ARVALID <= 1'b0;
            s_states <= s_3;
          end else begin  //保证是第一次进行写/读
            if (read_mode) begin
              `IO_MASTER_AWVALID <= 0; //将axi的数据传给io_master,如果不是写指令，这个值是0
              `IO_MASTER_WVALID  <= 0; //将axi的数据传给io_master,如果不是写指令，这个值是0
              `IO_MASTER_ARVALID <= `MEM_ARVALID; //将axi的数据传给io_master,如果不是读指令，这个值是0
            end else if (write_mode) begin
              `IO_MASTER_AWVALID <= `MEM_AWVALID; //将axi的数据传给io_master,如果不是写指令，这个值是0
              `IO_MASTER_WVALID  <= `MEM_WVALID; //将axi的数据传给io_master,如果不是写指令，这个值是0
              `IO_MASTER_ARVALID <= 0; //将axi的数据传给io_master,如果不是读指令，这个值是0
            end else if (fetch_mode) begin
              `IO_MASTER_AWVALID <= 0; //将axi的数据传给io_master,如果不是写指令，这个值是0
              `IO_MASTER_WVALID  <= 0; //将axi的数据传给io_master,如果不是写指令，这个值是0
              `IO_MASTER_ARVALID <= `IFU_ARVALID; //将axi的数据传给io_master,如果不是读指令，这个值是0
            end
          end
        end else if (s_states == s_2) begin
          if (io_master_bvalid) begin
            if (`IO_MASTER_BREADY) begin
              if (io_master_bresp == 0) begin  //写正确
                `IO_MASTER_BREADY <= 1'b0;
                mem_access_done <= 1;
                s_states <= s_idle;
                xbar_decode <= 4'b0;
                write_mode <= 0;
              end
            end
          end
        end else if (s_states == s_3) begin
          if (io_master_rvalid) begin
            if (`IO_MASTER_RREADY) begin
              //// 根据sram一个地址对应一个字节数据的性质，已经soc中ram一
              //// 个地址对应8字节数据的性质进行一定处理
              case (`IO_MASTER_ARADDR & 32'b11)
                32'h0: begin
                  rdata <= io_master_rdata[31:0];
                end
                32'h1: begin
                  rdata <= {8'b0, io_master_rdata[31:8]};
                end
                32'h2: begin
                  rdata <= {16'b0, io_master_rdata[31:16]};
                end
                32'h3: begin
                  rdata <= {24'b0, io_master_rdata[31:24]};
                end
              endcase
              s_states <= s_idle;
              if (read_mode) begin
                mem_access_done <= 1'b1;
                read_mode <= 1'b0;
              end else if (fetch_mode) begin
                if_access_done <= 1'b1;
                fetch_mode <= 1'b0;
              end
              xbar_decode <= 4'b0;
            end else begin
              if (read_mode) begin
                `IO_MASTER_RREADY <= `MEM_RREADY;
              end else if (fetch_mode) begin
                `IO_MASTER_RREADY <= `IFU_RREADY;
              end
            end
          end
        end
      end
    end
  end

  //======================================================================================
  // ICACHE
  //======================================================================================

  //=====================================================================================
  // ICACHE与SDRAM
  //=====================================================================================
  always @(posedge clock) begin
    if (reset) begin
    end else begin
      if (xbar_decode == 4'b1111) begin
        if (s_states == s_0) begin
          `IO_MASTER_ARBURST <= 2'b01;  //递增突发
          `IO_MASTER_ARLEN   <= 8'h03;  //4次传输，突发长度16字节(因为arsize=3'010)
          if (`IO_MASTER_ARVALID & io_master_arready) begin
            `IO_MASTER_ARVALID <= 1'b0;
            s_states <= s_3;
          end else begin  //保证是第一次进行写/读
            if (fetch_mode) begin
              `IO_MASTER_ARVALID <= `IFU_ARVALID; //将axi的数据传给io_master,如果不是读指令，这个值是0
            end else begin
              `IO_MASTER_ARVALID <= 0;
            end
          end
        end else if (s_states == s_3) begin
          `IO_MASTER_RREADY <= `IFU_RREADY;
          if (io_master_rvalid) begin
            if (`IO_MASTER_RREADY) begin
              s_states    <= s_3;
              sdram_rdata <= {sdram_rdata[95:0], io_master_rdata[31:0]};
              if (io_master_rlast) begin
                s_states      <= s_4;  //等待icacheok
                sdram_read_ok <= 1'b1;
              end
            end else begin
              if (fetch_mode) begin
                `IO_MASTER_RREADY <= `IFU_RREADY; //将axi的数据传给io_master,如果不是读指令，这个值是0
              end else begin
                `IO_MASTER_RREADY <= 0;
              end
            end
          end
        end else if (s_states == s_4) begin
          if (icache_ok == 1'b1) begin
            xbar_decode   <= 4'b0;
            sdram_read_ok <= 1'b0;
            s_states <= s_idle;
            fetch_mode <= 1'b0;
          end
        end
      end
    end
  end

  //=====================================================================================
  // AXI总线与内部设备通信
  //=====================================================================================
  wire [31:0] internal_slave_rdata;
  wire        internal_slave_arready;
  wire        internal_slave_awready;
  wire        internal_slave_wready;
  wire        internal_slave_rvalid;
  reg         internal_ren;
  reg         internal_wen;

  ysyx_22050499_ALL_SLAVE internal_slave (
      .clock        (clock),
      .reset        (reset),
      .raddr        (`MEM_ADDR),
      .waddr        (`MEM_ADDR),
      .wdata        (`MEM_WDATA),
      .wstrb        (`MEM_WSTRB),
      .xbar_decode  (xbar_decode),
      .ren          (internal_ren),
      .wen          (internal_wen),
      .slave_rdata  (internal_slave_rdata),
      .slave_arready(internal_slave_arready),
      .slave_awready(internal_slave_awready),
      .slave_wready (internal_slave_wready),
      .slave_rvalid (internal_slave_rvalid)
  );
  always @(posedge clock) begin
    /* ----------------CLINT --------------*/
    if (reset) begin
      internal_ren <= 0;
      internal_wen <= 0;
    end else if (xbar_decode == 4'b0001) begin
      if (`MEM_ARVALID) begin  //相当于ren
        if (internal_slave_arready) begin
          internal_ren    <= 1'b1;
        end
      end
      // 等待slave读完毕，接受slave读出的数据
      if (internal_slave_rvalid) begin
        if (`MEM_RREADY) begin
          internal_ren <= 1'b0;
          xbar_decode  <= 4'b0;
          read_mode <= 1'b0;
          rdata        <= internal_slave_rdata;
          mem_access_done  <= 1'b1;  //访存完成
          s_states <= s_idle; //因为之前进入了传值状态s_0,这里我懒得实现状态机
        end
      end

      //传送写地址给从设备
      if (`MEM_AWVALID) begin
        if (internal_slave_awready) begin
          //...
        end
      end

      // 传送写数据等给从设备
      if (`MEM_WVALID) begin
        if (internal_slave_wready) begin
          // 通信是不存在的，所以这里相当于乱写
        end
      end
    end
  end
endmodule
