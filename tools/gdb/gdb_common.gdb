# =========================================================================
# gdb_common.gdb - gdb 公共初始化(连接 J-Link GDB Server)
# 前提:jlink\gdb_server.bat 已在后台运行(端口见 config\paths.bat)
# 用法示例:
#   arm-none-eabi-gdb.exe <工程.elf> -batch -x tools\gdb\gdb_common.gdb ^
#       -ex "p g_counter" -ex "detach"
# 注意:端口在此写死,若修改 config 的 GDB_PORT 需同步改本行
# =========================================================================

# 禁交互确认:批量模式遇 y/n 询问会卡死
set confirm off
# 禁分页:输出满屏不再等待按键
set pagination off
# 结构体/数组按多行缩进打印
set print pretty on
# 连接 GDB Server;extended-remote 支持 load/detach 等完整控制
# 连接后目标默认停机,可直接读内存/设断点
target extended-remote :2333
echo [gdb] connected to J-Link GDB Server\n
