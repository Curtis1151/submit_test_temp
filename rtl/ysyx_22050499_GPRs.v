module ysyx_22050499_GPRs #(
    parameter ADDR_WIDTH = 16, 
    parameter DATA_WIDTH = 32
) (
    input                           clock,
    input                           reset,
    input [DATA_WIDTH-1:0]          wdata,
    input [3:0]                     waddr,
    input [3:0]                     rs1,
    input [3:0]                     rs2,
    input                           wen,
    //output  reg [DATA_WIDTH-1:0] rf [ADDR_WIDTH-1:0], //寄存器
    output  [DATA_WIDTH-1:0]     rs1_data,
    output  [DATA_WIDTH-1:0]     rs2_data
);
    reg [DATA_WIDTH-1:0] rf [ADDR_WIDTH-1:0]; //寄存器
    assign rs1_data = rf[rs1]; //输出rs1的值
    assign rs2_data = rf[rs2]; //输出rs1的值

    always @(posedge clock) begin
        if (reset) begin
            rf[0] <= 0;
            rf[1] <= 0;
            rf[2] <= 0;
            rf[3] <= 0;
            rf[4] <= 0;
            rf[5] <= 0;
            rf[6] <= 0;
            rf[7] <= 0;
            rf[8] <= 0;
            rf[9] <= 0;
            rf[10] <= 0;
            rf[11] <= 0;
            rf[12] <= 0;
            rf[13] <= 0;
            rf[14] <= 0;
            rf[15] <= 0;
        end else begin
            rf[0] <= 0;           //0号寄存器的特性
            if (wen && (waddr != 4'b0)) rf[waddr] <= wdata;
        end
    end

endmodule

