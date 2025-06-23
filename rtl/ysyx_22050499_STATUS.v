module ysyx_22050499_STATUS (
    input        clock,
    output [3:0] status
);
// status = 0 : 取指
// ---
// status = 1 : 译码
// ---
// status = 2 : 跳转类指令(jal,jalr,B-type, Ecall, Mret)的EXE阶段
// status = 3 : MEM阶段 (空)
// status = 4 : 跳转类指令的WB阶段: 写Rd
// ---
// status = 5 :  I-type(运算类) + R-type + U-type + CSR相关指令: EXE阶段
// status = 6 :  MEM阶段 (空) 多了一个fence_i来刷新icache
// status = 7 :  I-type(运算类) + R-type + U-type:  WB阶段: 写入Rd;
// ---
// status = 8 : S-type: EXE
// status = 9 : MEM阶段: 写内存
// status = A : WB阶段: (空)
// ---
// status = B: LOAD: EXE
// status = C: MEM阶段: 访存
// status = D: LOAD: 写Rd

endmodule
