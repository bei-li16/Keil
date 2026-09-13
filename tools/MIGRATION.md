# 调试工具集迁移记录(2026-09-13)

## 决策

仓库曾短暂存在两套并行的调试工具:

- `tools/`(dt.bat,cmd 原生,工程无关,单入口子命令)
- `STM32_CubeIDE/DebugTools/dbg/`(.sh,Git Bash 工作流,绑定 FreeRTOS_Project 与本机路径)

目标:**只保留一套,AI 与人都有良好使用体验**。经对比分析,选择 **以 `tools/dt.bat` 为唯一基座,
从 DebugTools 移植能力,DebugTools 退役**(git 历史见提交 `fd2d08d`,经验已并入本 README)。

理由概要:

1. dt.bat 的架构与目标同构——原子子命令 + 退出码契约 + 固定输出格式 + 文档化 AI 约定,
   缺的只是"自愈与进程管理"这一块内容;反向迁移则要重建整个架构与文档体系。
2. DebugTools 真正稀缺的是三段实测坑位知识(探针恢复序列、FPB/DWT 寄存器清理、降频与端口选择),
   属于纯内容,翻译成 bat 子命令零损失;架构搬家则难得多。
3. dt.bat 是远程活跃演进的产物,以其为基座与仓库历史一致,不产生新的分叉。

## 已移植内容(来源 → 去向)

| DebugTools 原能力 | 去向 |
|---|---|
| `probe-reset.sh` 探针恢复 | `dt probe-reset`(低速 1000kHz 重连+复位,自动先停 server) |
| `run.sh` 清 FPB/DWT 残留后放行 | `dt run`(w4 0xE0002000/0xE0001020-1050) |
| `server-stop.sh` 停 GDB Server | `dt server-stop`(兼容 OpenOCD,含进程存活校验) |
| flash.gdb "烧录后停在入口"语义 | `dt flash --hold`(复位后保持暂停) |
| README 五条踩坑铁律 + 故障速查 | README「铁律」章节 + FAQ 扩充 |
| logs.sh 任务日志统计验收 | `uart_capture.py --count <正则> --duration <秒>` |
| env.sh 降频/端口经验 | `paths.bat` 新增 `PROBE_SPEED=1000`,FAQ 记录 winnat 端口坑 |

新增配套:`dt halt`(暂停运行中的目标)、`dt.sh`(Git Bash/WSL 转发壳)、
根 `.gitattributes` 增加 `*.sh eol=lf` / `*.py eol=lf`。

## 实测教训(给后来者)

- **不要把 .bat 转成 UTF-8 + `chcp 65001`**:cmd 批处理解析器在 65001 代码页下对多字节行
  的文件偏移会计错,REM 被拦腰截断成 `'EM' is not recognized`,goto/label 全乱。
  .bat 保持 GBK+CRLF;跨终端的成败判断只依赖退出码和 ASCII 标记(`[OK]`/`[ERROR]`/`[FAIL]`)。

## 验收冒烟清单

```
dt check → dt probe-reset → dt server(后台) → dt read <elf> <全局变量>
→ dt server-stop → dt halt → dt run → dt uart --list → ./dt.sh check(Git Bash)
```
