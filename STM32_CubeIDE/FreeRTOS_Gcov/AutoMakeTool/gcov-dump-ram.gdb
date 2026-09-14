# gcov-dump-ram.gdb —— 方案 B(RAM 缓冲)提取(GDB Server 路线,备选)
# 主推 gcov-read-ram.jlink(J-Link Commander,无断点/无 inferior-call 风险)
#
# 两个实测坑位:
#   1. J-Link GDB Server 连接可能复位目标,已有计数会被清零,连接后需重跑采集场景
#   2. gcov_buf 是数组,&gcov_buf+8192 会被按数组大小缩放,必须先转成字节指针
#   3. 【已禁止】不要在 GDB 里 call bsp_gcov_dump_all():inferior-call 会把 dump
#      调用链压到 halt 上下文的栈上(IDLE 仅 512B,曾实测栈溢出 → HardFault),
#      且其返回断点是 FPB 硬件比较器,强杀 GDB Server 后跨复位残留(见 README)
#      —— 本脚本直接读 Task1000ms 周期刷新好的缓冲,不执行任何目标代码
set pagination off
set $b = (unsigned char *)&gcov_buf
target extended-remote localhost:3333
interrupt
dump binary memory gcov_blob.bin $b ($b + 8192)
detach
kill
quit
