# flash.gdb —— 复位、下载、跑到 main，然后交由后续命令
set pagination off
target extended-remote localhost:3333
monitor reset
load
break main
continue
echo \n=== 已停在 main，可继续单步/继续 ===\n
