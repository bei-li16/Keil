import os
import sys
import glob
from pathlib import Path

def generate_cmake(project_root, template_path, output_path="CMakeLists.txt"):
    """
    自动生成 CMakeLists.txt 文件
    :param project_root: 项目根目录
    :param template_path: CMakeLists 模板路径
    :param output_path: 输出文件路径
    """
    # 递归收集源文件 (.c, .cpp, .h, .hpp, .s)
    source_files = glob.glob(os.path.join(project_root, "**/*.[ch]pp"), recursive=True) + \
                   glob.glob(os.path.join(project_root, "**/*.s"), recursive=True) + \
                   glob.glob(os.path.join(project_root, "**/*.c"), recursive=True) + \
                   glob.glob(os.path.join(project_root, "**/*.h"), recursive=True)

    # 转换路径格式并过滤出源文件（排除头文件）
    c_cpp_sources = [
        str(Path(f).relative_to(project_root)).replace("\\", "/")
        for f in source_files 
        if f.endswith(('.c', '.cpp', '.s'))
    ]

    # 收集头文件目录并去重
    include_dirs = {
        str(Path(f).parent.relative_to(project_root)).replace("\\", "/")
        for f in source_files 
        if f.endswith(('.h', '.hpp'))
    }

    # 读取模板文件
    with open(template_path, "r", encoding="utf-8") as f:
        template = f.read()

    # 生成 CMake 代码块
    sources_block = "file(GLOB_RECURSE SOURCES\n    " + \
                    "\n    ".join(f'"{s}"' for s in sorted(c_cpp_sources)) + \
                    "\n)"

    includes_block = "include_directories(\n    " + \
                     "\n    ".join(f'"{d}"' for d in sorted(include_dirs)) + \
                     "\n)"

    # 替换占位符
    template = template.replace(
        "# =============================================================================\n"
        "# Auto-generated Section (DO NOT EDIT MANUALLY)\n"
        "# =============================================================================\n"
        "# AUTO_GENERATED_SOURCES\n"
        "# AUTO_GENERATED_INCLUDES",
        f"# =============================================================================\n"
        f"# Auto-generated Section (DO NOT EDIT MANUALLY)\n"
        f"# =============================================================================\n"
        f"{sources_block}\n"
        f"{includes_block}"
    )

    # 写入输出文件
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(template)
    print(f"Generated {output_path} with {len(c_cpp_sources)} sources and {len(include_dirs)} include dirs")

if __name__ == "__main__":
    # 使用示例
    project_root = "."          # 项目根目录
    template_path = "CMakeLists.template"
    output_path = "CMakeLists.txt"
    if len(sys.argv) > 3:
        project_root = sys.argv[1]
        template_path = sys.argv[2]
        output_path = sys.argv[3]
        print(f"使用自定义项目根目录: {project_root}")
        print(f"使用自定义CMake模板: {template_path}")
        print(f"使用自定义输出路径: {output_path}")
    else:
        print("使用默认项目根目录: 当前目录")
    
    generate_cmake(
        project_root=project_root,
        template_path=template_path,
        output_path=output_path
    )