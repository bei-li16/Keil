# gcov-dump-semihost.gdb —— 方案 A(semihosting)的覆盖率提取脚本
# 前置:OpenOCD 已用工程根目录 FreeRTOS_Project.cfg 启动(GDB 端口 3333):
#        openocd -f ../FreeRTOS_Project.cfg
# 用法: arm-none-eabi-gdb -nx -batch -x gcov-dump-semihost.gdb build/FreeRTOS_STM32F429.elf
# 产物: semihosting_basedir 指定目录下的 gcov_blob.bin
#        -> python gcov-extract.py gcov_blob.bin -o build -> make gcov-report
set pagination off
target extended-remote localhost:3333
# 开启 semihosting 并指定主机落盘目录(按需修改)
monitor arm semihosting enable
monitor arm semihosting_basedir .
monitor reset
continue
interrupt
# 打开门控并触发一次导出(固件把记录流经 SYS_OPEN/SYS_WRITE 写成 gcov_blob.bin)
set var gcov_stream_enable = 1
call (void)bsp_gcov_dump_all()
detach
kill
quit
