# GCov 覆盖率测试使用指南

## 概述
本指南介绍如何使用 GCov 对 `bsp_led.c` 等源文件进行代码覆盖率测试。

## 准备工作
确保已安装 GNU ARM Embedded Toolchain，其中包含 GCov 工具。

## 基本使用方法

### 1. 查看帮助
```bash
mingw32-make gcov-help
```

### 2. 对单个文件进行覆盖率测试
```bash
# 对 bsp_led.c 进行覆盖率测试
mingw32-make GCOV_FILES="bsp_led.c" gcov-test
```

### 3. 对多个文件进行覆盖率测试
```bash
mingw32-make GCOV_FILES="bsp_led.c user_task.c" gcov-test
```

### 4. 使用通配符模式
```bash
# 对所有 bsp_*.c 文件进行覆盖率测试
mingw32-make GCOV_FILES="bsp_%.c" gcov-build
```

## 详细步骤

### 步骤1：编译项目（包含覆盖率插桩）
```bash
mingw32-make clean
mingw32-make GCOV_FILES="bsp_led.c" gcov-build
```

此时会在 `build/` 目录下生成：
- `bsp_led.o` - 目标文件（包含覆盖率信息）
- `bsp_led.gcno` - 图形文件（包含程序流图信息）

### 步骤2：在目标硬件上运行程序
```bash
mingw32-make GCOV_FILES="bsp_led.c" run
```

或者：
```bash
mingw32-make run FILE_SPECIFIC_CFLAGS="bsp_led.c=--coverage -fprofile-arcs -ftest-coverage"
```

程序运行后，会在 `build/` 目录下生成：
- `bsp_led.gcda` - 计数文件（包含代码执行次数）

### 步骤3：生成覆盖率报告
```bash
mingw32-make GCOV_FILES="bsp_led.c" gcov-report
```

报告文件会生成在 `gcov_output/` 目录：
- `bsp_led_report.txt` - 行覆盖率报告
- `bsp_led_branch.txt` - 分支覆盖率报告
- `../bsp_led.c.gcov` - 带行号和执行次数的源文件

### 步骤4：查看覆盖率结果
```bash
# 查看覆盖率报告
type gcov_output\bsp_led_report.txt

# 查看带注释的源文件
type bsp_led.c.gcov
```

## 覆盖率报告解读

### bsp_led.c.gcov 文件格式
- `#####` - 表示该行未执行
- 数字 - 表示该行执行的次数
- `-` - 表示非代码行（注释、空行、括号等）

### 示例输出
```
     13|    #####:    9:void Led_RedFlip(void)
     14|        -:   10:{
     15|    #####:   11:	HAL_GPIO_TogglePin(LED_RED_GPIO_Port, LED_RED_Pin);
     16|    #####:   12:}
```

`#####` 表示这些行在测试运行中未被调用。

## 高级用法

### 结合特定编译选项
```bash
mingw32-make GCOV_FILES="bsp_led.c" gcov-build FILE_SPECIFIC_CFLAGS="bsp_led.c=-O0 -DLED_DEBUG --coverage"
```

### 清理覆盖率文件
```bash
mingw32-make gcov-clean
```

### 完整工作流程
```bash
# 1. 清理环境
mingw32-make clean gcov-clean

# 2. 编译并运行
mingw32-make GCOV_FILES="bsp_led.c" gcov-test

# 3. 查看报告
type gcov_output\bsp_led_report.txt
type bsp_led.c.gcov
```

## 注意事项

1. **性能影响**：覆盖率插桩会增加代码大小和执行时间
2. **内存需求**：需要额外内存存储覆盖率数据
3. **目标硬件**：需要确保目标硬件有足够的资源
4. **文件系统**：某些嵌入式系统可能需要特殊处理来保存 .gcda 文件

## 故障排除

### 常见问题

1. **找不到 .gcda 文件**
   - 确保程序在目标硬件上实际运行
   - 检查文件系统写入权限

2. **链接错误**
   - 确保使用了 `--coverage -lgcov` 链接选项

3. **报告格式错误**
   - 确保 .gcno 和 .gcda 文件版本匹配

### 调试命令
```bash
# 检查生成的文件
dir build\*.gcno build\*.gcda

# 手动运行 gcov
arm-none-eabi-gcov build/bsp_led.gcda -o build

# 检查编译选项
mingw32-make debug-objs
```

## 总结

使用 GCov 进行覆盖率测试的完整流程：
1. 使用 `gcov-build` 编译项目（自动添加覆盖率选项）
2. 在目标硬件上运行程序生成 .gcda 文件
3. 使用 `gcov-report` 生成覆盖率报告
4. 分析报告找出未测试的代码路径

这样可以帮助你：
- 提高测试覆盖率
- 找出死代码
- 验证测试的有效性