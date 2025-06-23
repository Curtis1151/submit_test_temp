module ysyx_22050499_EXP(
    input [31:0]    inst,
    input [2:0]     ExtOp,
    output [31:0]   imm
); //扩展器
    reg [31:0] immI,immU,immS,immB,immJ;
    assign  immI = {{20{inst[31]}}, inst[31:20]};
    assign  immU = {inst[31:12],12'b0};
    assign  immS = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    assign  immB = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign  immJ = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

    assign  imm = ~ExtOp[2] & ~ExtOp[1] & ~ExtOp[0] ? immI :
                (~ExtOp[2] & ~ExtOp[1] &  ExtOp[0] ? immU :
                (~ExtOp[2] &  ExtOp[1] & ~ExtOp[0] ? immS :
                (~ExtOp[2] &  ExtOp[1] &  ExtOp[0] ? immB :
                ( ExtOp[2] & ~ExtOp[1] & ~ExtOp[0] ? immJ : 32'b0))));
    
endmodule
