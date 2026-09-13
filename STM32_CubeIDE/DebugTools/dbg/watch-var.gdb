# watch-var.gdb —— 监视变量（如状态机变量）的每次写变化，记录值+调用栈
# 用法：改下面 watch / printf 两行里的变量名（文本直接替换，不要用 GDB 便利变量间接引用，
#       否则不会生成硬件观察点），MAX_HITS 控制最多记录次数
# 原理：GDB 的 watch 在 Cortex-M 上走 DWT 硬件观察点，不拖慢 CPU 运行
set pagination off
target extended-remote localhost:3333
monitor reset
load
break main
continue

set $n = 20                # ← 最多记录多少次变化
watch my_state             # ← 改成要监视的变量名
commands
  silent
  printf "HIT: my_state = %d\n", my_state    # ← 同步改变量名
  bt 5
  set $n = $n - 1
  if $n <= 0
    detach
    quit
  end
  continue
end

continue
