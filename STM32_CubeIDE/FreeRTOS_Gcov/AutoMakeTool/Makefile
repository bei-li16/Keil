# ==============================================================================
# STM32 Makefile for FreeRTOS Project - Dynamic Source Discovery
# ==============================================================================
# 
# 使用说明:
#   mingw32-make help          - 显示此帮助信息
#   mingw32-make all           - 编译所有文件并生成elf、hex、bin文件
#   mingw32-make run           - 编译并下载hex文件到STM32
#   mingw32-make clean         - 清理构建目录
#   mingw32-make distclean     - 完全清理（包括项目根目录的输出文件）
#   mingw32-make rebuild       - 清理并重新构建
#   mingw32-make info          - 显示内存使用情况
#   mingw32-make debug-objs     - 调试：显示对象文件路径
#   mingw32-make print-sources  - 调试：显示发现的源文件
# 
# 自定义构建:
#   mingw32-make PROJECT=MyProject            - 指定项目名称
#   mingw32-make LDSCRIPT=custom.ld           - 使用自定义链接脚本
#   mingw32-make COMPILER_DIR=/path/to/tools   - 指定工具链路径
#   mingw32-make BUILD_DIR=output              - 指定构建输出目录
# 
# 示例:
#   mingw32-make -j4                           - 4线程并行编译
#   mingw32-make clean all                     - 清理后重新构建
#   mingw32-make info | grep "text\|data\|bss" - 查看内存占用
# ==============================================================================

# 项目名称（可通过命令行参数覆盖）
PROJECT ?= FreeRTOS_STM32F429

# Backwards-compat: accept `PROJECT_NAME` and `LINKER_FILE` if Build.bat provides them
ifdef PROJECT_NAME
PROJECT := $(PROJECT_NAME)
endif

ifneq ($(strip $(LINKER_FILE)),)
LDSCRIPT := $(PROJECT_ROOT)$(LINKER_FILE)
endif

# 工具链配置 - 自动检测平台
## Toolchain paths (defaults can be overridden by environment or command line)
ifeq ($(OS),Windows_NT)
    MAKE_DIR ?= C:/ST/STM32CubeIDE_1.18.1/STM32CubeIDE/plugins/com.st.stm32cube.ide.mcu.externaltools.make.win32_2.2.0.202409170845/tools/bin
#     COMPILER_DIR ?= D:\Software\arm-gnu-toolchain-14.3.rel1-mingw-w64-x86_64-arm-none-eabi\bin
    COMPILER_DIR ?= C:/ST/STM32CubeIDE_1.18.1/STM32CubeIDE/plugins/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.13.3.rel1.win32_1.0.0.202411081344/tools/bin
    # CubeIDE 的 make.exe 自带 sh.exe 并优先用它执行配方,cmd 内建命令(del/rmdir/if)不可用,
    # 因此 Windows 下文件操作命令也必须用 sh 语法
    RM = rm -f
    RM_FILE = rm -f
    RMDIR = rm -rf
    MKDIR = mkdir -p
    PATH_SEP = \\
else
    MAKE_DIR ?= /opt/st/stm32cubeide_1.18.1/plugins/com.st.stm32cube.ide.mcu.externaltools.make.linux_2.2.0.202409170845/tools/bin
    COMPILER_DIR ?= /opt/st/stm32cubeide_1.18.1/plugins/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.13.3.rel1.linux_1.0.0.202411081344/tools/bin
    RM = rm -f
    RM_FILE = rm -f
    RMDIR = rm -rf
    MKDIR = mkdir
    PATH_SEP = /
endif

# 工具链可执行文件
CC = $(COMPILER_DIR)$(PATH_SEP)arm-none-eabi-gcc
AS = $(COMPILER_DIR)$(PATH_SEP)arm-none-eabi-gcc -x assembler-with-cpp
CP = $(COMPILER_DIR)$(PATH_SEP)arm-none-eabi-objcopy
SZ = $(COMPILER_DIR)$(PATH_SEP)arm-none-eabi-size

# Allow overriding toolchain by specifying e.g. COMPILER_DIR=/path/to/toolchain

# 目录设置
BUILD_DIR = build
PROJECT_ROOT ?= ../

# Parallel build: if MAKEFLAGS not provided, set default based on platform
ifndef MAKEFLAGS
	ifeq ($(OS),Windows_NT)
		MAKEFLAGS += -j$(NUMBER_OF_PROCESSORS)
	else
		MAKEFLAGS += -j$(shell nproc 2>/dev/null || echo 4)
	endif
endif

# 链接脚本（可通过命令行参数覆盖）
LDSCRIPT ?= $(PROJECT_ROOT)STM32F429IGTX_FLASH.ld

# 编译选项
CFLAGS = -mcpu=cortex-m4 \
         -std=gnu11 \
         -g3 \
         -DDEBUG \
         -DSTM32F429xx \
         -DUSE_HAL_DRIVER \
         -O0 \
         -ffunction-sections \
         -fdata-sections \
         -Wall \
         --specs=nano.specs \
         -mfpu=fpv4-sp-d16 \
         -mfloat-abi=hard \
         -mthumb \
         -DUSE_BANK_DEFAULT \
         -DHSE_VALUE=25000000 \
         -DUSE_FULL_LL_DRIVER \
         -DSTM32F429IGTx \
         -DPRINT_COM=huart1 \
         -DW25Q_COM=hspi5

# 特定文件的编译选项 - 支持为单个文件或文件模式指定额外编译选项
# 使用方法示例:
#   mingw32-make FILE_SPECIFIC_CFLAGS="bsp_led.c=-O2 -DLED_DEBUG user_task.c=-O3"
#   mingw32-make FILE_SPECIFIC_CFLAGS="bsp_%.c=-O2 -DBSP_DEBUG"
#   mingw32-make FILE_SPECIFIC_CFLAGS="critical_%.c=-O3 -funroll-loops"
# 支持通配符模式: %.c 匹配所有.c文件, prefix_%.c 匹配特定前缀的.c文件
FILE_SPECIFIC_CFLAGS ?=

# GCov 覆盖率测试支持
# 覆盖率编译选项
GCOV_CFLAGS = --coverage -fprofile-arcs -ftest-coverage
GCOV_LDFLAGS = --coverage -lgcov

# 覆盖率文件目录
GCOV_DIR = gcov_output

# 需要进行覆盖率测试的文件列表
GCOV_FILES ?= bsp_led.c

# 覆盖率数据导出传输方式(见 BSP/GCOV 与 GCOV_EXPORT_README.md):
#   ram      数据写入静态缓冲,GDB dump binary memory 取回(默认,最稳)
#   rtt      经 SEGGER RTT 通道 0 实时流出,JLinkRTTLogger 落盘
#   semihost 经 semihosting 文件调用直接写主机文件(需 OpenOCD/J-Link 开 semihosting)
GCOV_TRANSPORT ?= ram
ifeq ($(GCOV_TRANSPORT),rtt)
GCOV_TRANSPORT_DEFINE := -DGCOV_TRANSPORT_RTT
else ifeq ($(GCOV_TRANSPORT),semihost)
GCOV_TRANSPORT_DEFINE := -DGCOV_TRANSPORT_SEMIHOST
else
GCOV_TRANSPORT_DEFINE := -DGCOV_TRANSPORT_RAM
endif

# 获取特定文件的编译选项
# 参数: $(1) 源文件路径
define GET_FILE_CFLAGS
$(strip \
$(foreach entry,$(FILE_SPECIFIC_CFLAGS), \
$(if $(filter $(notdir $(1)),$(firstword $(subst =, ,$(entry)))), \
$(patsubst $(firstword $(subst =, ,$(entry)))=%,%,$(entry)))))
endef

# 链接选项
LDFLAGS = -mcpu=cortex-m4 \
          -T$(LDSCRIPT) \
          -Wl,--gc-sections \
          -static \
          --specs=nano.specs \
          -mfpu=fpv4-sp-d16 \
          -mfloat-abi=hard -mthumb \
          -Wl,--start-group \
          -lc \
          -lm \
          -Wl,--end-group \
          -Wl,-Map=$(BUILD_DIR)/$(PROJECT).map

# 包含目录 - 保持与原来一致
INCLUDES = -I"$(PROJECT_ROOT)Core/Inc" \
           -I"$(PROJECT_ROOT)Drivers/STM32F4xx_HAL_Driver/Inc" \
           -I"$(PROJECT_ROOT)Drivers/STM32F4xx_HAL_Driver/Inc/Legacy" \
           -I"$(PROJECT_ROOT)Middlewares/Third_Party/FreeRTOS/Source/include" \
           -I"$(PROJECT_ROOT)Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS_V2" \
           -I"$(PROJECT_ROOT)Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS" \
           -I"$(PROJECT_ROOT)Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F" \
           -I"$(PROJECT_ROOT)Drivers/CMSIS/Device/ST/STM32F4xx/Include" \
           -I"$(PROJECT_ROOT)Drivers/CMSIS/Include" \
           -I"$(PROJECT_ROOT)BSP/Inc" \
           -I"$(PROJECT_ROOT)BSP" \
           -I"$(PROJECT_ROOT)BSP/LED/Inc" \
           -I"$(PROJECT_ROOT)BSP/LOG/Inc" \
           -I"$(PROJECT_ROOT)BSP/USER_TASK/Inc" \
           -I"$(PROJECT_ROOT)BSP/W25Q128/Inc" \
           -I"$(PROJECT_ROOT)BSP/GCOV/Inc"


# ==============================================================================
# 动态源文件发现 - 使用 Make 的 wildcard/patsubst（不依赖 PowerShell）
# - 采用显式目录模式发现常用源码目录，保持简单可靠。
# ==============================================================================
# Core C sources
CORE_C_SOURCES := $(wildcard $(PROJECT_ROOT)Core/Src/*.c)

# HAL driver sources
HAL_C_SOURCES := $(wildcard $(PROJECT_ROOT)Drivers/STM32F4xx_HAL_Driver/Src/*.c)

# FreeRTOS sources - try to auto-collect commonly-used paths with wildcard
# wildcard does not support deep recursive globs portably, so collect top-level
# Source/*.c, Source/*/*.c and Source/*/*/*.c which covers typical structure.
FREERTOS_C_SOURCES := $(wildcard $(PROJECT_ROOT)Middlewares/Third_Party/FreeRTOS/Source/*.c) \
				$(wildcard $(PROJECT_ROOT)Middlewares/Third_Party/FreeRTOS/Source/*/*.c) \
				$(wildcard $(PROJECT_ROOT)Middlewares/Third_Party/FreeRTOS/Source/*/*/*.c) \
				$(wildcard $(PROJECT_ROOT)Middlewares/Third_Party/FreeRTOS/Source/*/*/*/*.c)

# BSP sources (common pattern for each component)
BSP_C_SOURCES := $(wildcard $(PROJECT_ROOT)BSP/*/Src/*.c)

# 汇编源文件（启动文件）
ASM_SOURCES := $(wildcard $(PROJECT_ROOT)Core/Startup/*.s)

# 合并所有C源文件（确保没有空条目）
C_SOURCES = $(filter-out ,$(CORE_C_SOURCES) $(HAL_C_SOURCES) $(FREERTOS_C_SOURCES) $(BSP_C_SOURCES))
C_SOURCES := $(sort $(C_SOURCES))

# 对象文件 - 所有中间文件统一放到build目录下，不保持原有目录结构
C_OBJS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
ASM_OBJS = $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
OBJS = $(C_OBJS) $(ASM_OBJS)

# 为每个源文件创建构建规则
define COMPILE_C_TEMPLATE
$(BUILD_DIR)/$(notdir $(1:.c=.o)): $(1) | $(BUILD_DIR)
	$$(eval FILE_CFLAGS := $$(call GET_FILE_CFLAGS,$(1)))
	$$(if $$(FILE_CFLAGS),@echo "Using custom flags for $(notdir $(1)): $$(FILE_CFLAGS)",)
	$(CC) $(CFLAGS) $$(FILE_CFLAGS) $(INCLUDES) -c $(1) -o $$@
endef

define COMPILE_ASM_TEMPLATE
$(BUILD_DIR)/$(notdir $(1:.s=.o)): $(1) | $(BUILD_DIR)
	@$(AS) $(CFLAGS) $(INCLUDES) -c $(1) -o $$@
endef

# 为每个源文件生成规则
$(foreach src,$(C_SOURCES),$(eval $(call COMPILE_C_TEMPLATE,$(src))))
$(foreach src,$(ASM_SOURCES),$(eval $(call COMPILE_ASM_TEMPLATE,$(src))))

# 默认目标 - 如果没有指定目标则显示帮助
.DEFAULT_GOAL := help

# 主要构建目标
all: $(BUILD_DIR)/$(PROJECT).elf $(BUILD_DIR)/$(PROJECT).hex $(BUILD_DIR)/$(PROJECT).bin $(BUILD_DIR)/$(PROJECT).map $(BUILD_DIR)/$(PROJECT).dis

# 运行目标 - 下载hex文件到STM32
# download.bat 是 Windows 批处理,sh 环境下需经 cmd 执行
run: $(BUILD_DIR)/$(PROJECT).hex
	@echo Downloading $(PROJECT).hex to STM32...
	@cmd //c download.bat $(BUILD_DIR)/$(PROJECT).hex

# 创建构建目录
$(BUILD_DIR):
	@echo Creating build directory...
	@$(MKDIR) $(BUILD_DIR)



# 链接生成elf文件
# 目标文件必须位于库文件(-lc/-lm/-lgcov)之前:链接器单遍扫描,先看到对象文件的
# 未解析符号,才能从后面的库拉取对应成员;否则 -lgcov 在扫描时无引用,libgcov 不会被拉入
$(BUILD_DIR)/$(PROJECT).elf: $(OBJS) | $(BUILD_DIR)
	@echo Linking: $@
	$(CC) $(OBJS) $(LDFLAGS) -o $@

# 生成map文件
$(BUILD_DIR)/$(PROJECT).map: $(BUILD_DIR)/$(PROJECT).elf | $(BUILD_DIR)
	@echo "Generating MAP: $@"

# 生成反汇编文件
$(BUILD_DIR)/$(PROJECT).dis: $(BUILD_DIR)/$(PROJECT).elf | $(BUILD_DIR)
	@echo "Generating DIS: $@"
	$(COMPILER_DIR)$(PATH_SEP)arm-none-eabi-objdump -d $< > $@

# 生成hex文件
$(BUILD_DIR)/$(PROJECT).hex: $(BUILD_DIR)/$(PROJECT).elf | $(BUILD_DIR)
	@echo Generating HEX: $@
	$(CP) -O ihex $< $@

# 生成bin文件
$(BUILD_DIR)/$(PROJECT).bin: $(BUILD_DIR)/$(PROJECT).elf | $(BUILD_DIR)
	@echo Generating BIN: $@
	$(CP) -O binary $< $@

# 显示内存使用情况
info: $(BUILD_DIR)/$(PROJECT).elf
	$(SZ) $<

# 清理构建文件
clean:
	@echo Cleaning build directory...
	@$(RMDIR) $(BUILD_DIR) 2>/dev/null || true

# 完全清理 - 删除build目录和项目根目录的输出文件
distclean: clean
	@echo Cleaning project files...
	@$(RM_FILE) ../$(PROJECT).elf
	@$(RM_FILE) ../$(PROJECT).hex
	@$(RM_FILE) ../$(PROJECT).bin
	@$(RM_FILE) ../$(PROJECT).map
	@$(RM_FILE) ../$(PROJECT).dis

# 重新构建
rebuild: clean all

# 调试目标：显示发现的源文件
print-sources:
	@echo === CORE C SOURCES ===
	@echo $(CORE_C_SOURCES)
	@echo === HAL C SOURCES ===
	@echo $(HAL_C_SOURCES)
	@echo === FREERTOS C SOURCES ===
	@echo $(FREERTOS_C_SOURCES)
	@echo === BSP C SOURCES ===
	@echo $(BSP_C_SOURCES)
	@echo === ASM SOURCES ===
	@echo $(ASM_SOURCES)

# 显示帮助信息
help:
	@echo "==============================================================================="
	@echo "STM32 FreeRTOS Makefile - Dynamic Source Discovery Build System"
	@echo "==============================================================================="
	@echo ""
	@echo "Basic Commands:"
	@echo "  mingw32-make help          - Show this help information"
	@echo "  mingw32-make all           - Compile all files and generate elf, hex, bin, map, dis files"
	@echo "  mingw32-make run           - Build and download hex file to STM32"
	@echo "  mingw32-make clean         - Clean build directory"
	@echo "  mingw32-make distclean     - Complete clean (including project root output files)"
	@echo "  mingw32-make rebuild       - Clean and rebuild"
	@echo "  mingw32-make info          - Show memory usage"
	@echo ""
	@echo "Debug Commands:"
	@echo "  mingw32-make debug-objs    - Debug: Show object file paths"
	@echo "  mingw32-make print-sources - Debug: Show discovered source files"
	@echo ""
	@echo "Custom Build:"
	@echo "  mingw32-make PROJECT=MyProject            - Specify project name"
	@echo "  mingw32-make LDSCRIPT=custom.ld           - Use custom linker script"
	@echo "  mingw32-make COMPILER_DIR=/path/to/tools   - Specify toolchain path"
	@echo "  mingw32-make BUILD_DIR=output              - Specify build output directory"
	@echo ""
	@echo "File-Specific Compilation Flags:"
	@echo "  mingw32-make FILE_SPECIFIC_CFLAGS=\"file.c=-O2 other.c=-DDEBUG\""
	@echo "  mingw32-make FILE_SPECIFIC_CFLAGS=\"bsp_%%.c=-O2 -DBSP_DEBUG\""
	@echo "  mingw32-make FILE_SPECIFIC_CFLAGS=\"critical_%%.c=-O3 -funroll-loops\""
	@echo ""
	@echo "GCov Coverage Testing:"
	@echo "  mingw32-make gcov-help                      - Show GCov usage guide"
	@echo "  mingw32-make GCOV_FILES=\"bsp_led.c\" gcov-test   - Complete coverage test"
	@echo "  mingw32-make GCOV_FILES=\"file.c\" gcov-build     - Build with coverage"
	@echo "  mingw32-make gcov-report                    - Generate coverage reports"
	@echo ""
	@echo "Examples:"
	@echo "  mingw32-make -j4                           - 4-thread parallel compilation"
	@echo "  mingw32-make clean all                     - Clean and rebuild"
	@echo "  mingw32-make info | grep 'text\\|data\\|bss' - View memory usage"
	@echo ""

# 调试目标：显示对象文件路径
debug-objs:
	@echo === PROJECT_ROOT ===
	@echo $(PROJECT_ROOT)
	@echo === ALL C SOURCES ===
	@echo $(C_SOURCES)
	@echo === C OBJS ===
	@echo $(C_OBJS)
	@echo === ASM OBJS ===
	@echo $(ASM_OBJS)

# 调试目标：测试文件特定编译选项
test-file-flags:
	@echo === Testing File-Specific Compilation Flags ===
	@echo "Example test: checking flags for user_task.c"
	@$(eval USER_TASK_FLAGS := $(call GET_FILE_CFLAGS,$(PROJECT_ROOT)BSP/USER_TASK/Src/user_task.c))
	@echo "Flags for user_task.c: $(USER_TASK_FLAGS)"
	@echo ""
	@echo "Setting test flags for user_task.c"
	@$(eval FILE_SPECIFIC_CFLAGS := user_task.c=-O2 -DTEST_FLAG)
	@$(eval USER_TASK_FLAGS := $(call GET_FILE_CFLAGS,$(PROJECT_ROOT)BSP/USER_TASK/Src/user_task.c))
	@echo "Flags for user_task.c with test: $(USER_TASK_FLAGS)"
	@echo ""
	@echo "Setting pattern flags for all bsp_*.c files"
	@$(eval FILE_SPECIFIC_CFLAGS := bsp_%.c=-O3 -DBSP_PATTERN)
	@$(foreach src,$(filter %/bsp_%.c,$(C_SOURCES)), \
		@echo "Flags for $(notdir $(src)): $(call GET_FILE_CFLAGS,$(src))";)

# 覆盖率测试目标
# 为指定文件启用覆盖率测试
gcov-build:
	@echo "Building with GCov coverage for files: $(GCOV_FILES)"
	@$(foreach file,$(GCOV_FILES), \
		$(eval CURRENT_FLAGS := $(call GET_FILE_CFLAGS,$(file))) \
		$(eval UPDATED_FLAGS := $(CURRENT_FLAGS) $(GCOV_CFLAGS)) \
		$(eval FILE_SPECIFIC_CFLAGS := $(file)=$(UPDATED_FLAGS) $(FILE_SPECIFIC_CFLAGS)) \
		@echo "Adding GCov flags for $(file): $(UPDATED_FLAGS)";)
	$(eval FILE_SPECIFIC_CFLAGS := user_task.c=-DGCOV_BUILD bsp_gcov.c=$(GCOV_TRANSPORT_DEFINE) $(FILE_SPECIFIC_CFLAGS))
	@echo "GCOV transport: $(GCOV_TRANSPORT) [$(GCOV_TRANSPORT_DEFINE)]"
	$(MAKE) clean all FILE_SPECIFIC_CFLAGS="$(FILE_SPECIFIC_CFLAGS)" LDFLAGS="$(LDFLAGS) $(GCOV_LDFLAGS)"

# 生成覆盖率报告
gcov-report:
	@echo "Generating GCov coverage report..."
	@$(MKDIR) $(GCOV_DIR)
	@for f in $(GCOV_FILES); do \
		$(COMPILER_DIR)/arm-none-eabi-gcov $(BUILD_DIR)/$${f%.c}.gcda -o $(BUILD_DIR) > $(GCOV_DIR)/$${f%.c}_report.txt 2>&1; \
		$(COMPILER_DIR)/arm-none-eabi-gcov $(BUILD_DIR)/$${f%.c}.gcda -o $(BUILD_DIR) --branch-probabilities > $(GCOV_DIR)/$${f%.c}_branch.txt 2>&1; \
	done
	@echo "Coverage reports generated in $(GCOV_DIR) directory"

# 清理覆盖率文件
gcov-clean:
	@echo "Cleaning GCov files..."
	@rm -f $(BUILD_DIR)/*.gcno $(BUILD_DIR)/*.gcda
	@rm -rf $(GCOV_DIR)

# 完整的覆盖率测试流程：编译->运行->生成报告
gcov-test: gcov-build run gcov-report

# 显示覆盖率使用说明
gcov-help:
	@echo "==============================================================================="
	@echo "GCov Coverage Testing Guide"
	@echo "==============================================================================="
	@echo ""
	@echo "Basic Usage:"
	@echo "  mingw32-make GCOV_FILES=\"bsp_led.c\" gcov-build    - Build with coverage for specific files"
	@echo "  mingw32-make gcov-test                              - Complete coverage test workflow"
	@echo "  mingw32-make gcov-report                            - Generate coverage reports"
	@echo "  mingw32-make gcov-clean                             - Clean coverage files"
	@echo ""
	@echo "Examples:"
	@echo "  mingw32-make GCOV_FILES=\"bsp_led.c user_task.c\" gcov-test"
	@echo "  mingw32-make GCOV_FILES=\"bsp_%.c\" gcov-build      - Coverage for all bsp_*.c files"
	@echo ""
	@echo "Coverage Reports:"
	@echo "  Reports are generated in $(GCOV_DIR)/ directory"
	@echo "  *_report.txt    - Line coverage report"
	@echo "  *_branch.txt    - Branch coverage report"
	@echo ""

.PHONY: all run clean distclean rebuild info print-sources debug-objs help test-file-flags gcov-build gcov-report gcov-clean gcov-test gcov-help