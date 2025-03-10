import sys
import argparse
from collections import namedtuple

# 定义HEX记录类型
Record = namedtuple('Record', ['address', 'data', 'type', 'extended_address'])

def parse_hex_line(line):
    """解析单行HEX记录"""
    line = line.strip()
    if not line.startswith(':'):
        return None
    byte_count = int(line[1:3], 16)
    address = int(line[3:7], 16)
    record_type = int(line[7:9], 16)
    data = bytes.fromhex(line[9:9+byte_count*2])
    checksum = int(line[-2:], 16)
    # 简化的校验和验证（可选）
    return Record(address, data, record_type, None)

def parse_hex_file(filename):
    """解析整个HEX文件，返回地址范围列表和记录列表"""
    address_ranges = []
    records = []
    current_extended_address = 0x0000  # 处理扩展线性地址
    
    with open(filename, 'r') as f:
        for line in f:
            record = parse_hex_line(line)
            if not record:
                continue
            
            # 处理扩展线性地址（0x04类型）
            if record.type == 0x04:
                current_extended_address = int.from_bytes(record.data, byteorder='big') << 16
                records.append(record)
                continue
            elif record.type == 0x00:  # 数据记录
                absolute_address = current_extended_address + record.address
                end_address = absolute_address + len(record.data) - 1
                address_ranges.append( (absolute_address, end_address) )
                records.append(record._replace(extended_address=current_extended_address))
            else:
                records.append(record)
                
    return address_ranges, records

def check_overlap(ranges1, ranges2):
    """检测两个地址范围列表是否有重叠"""
    sorted_ranges = sorted(ranges1 + ranges2, key=lambda x: x[0])
    for i in range(1, len(sorted_ranges)):
        prev_end = sorted_ranges[i-1][1]
        curr_start = sorted_ranges[i][0]
        if curr_start <= prev_end:
            return (sorted_ranges[i-1], sorted_ranges[i])
    return None

def merge_hex_files(file1, file2, output):
    """合并两个HEX文件"""
    # 解析文件并获取地址范围
    ranges1, records1 = parse_hex_file(file1)
    ranges2, records2 = parse_hex_file(file2)
    
    # 检测地址冲突
    conflict = check_overlap(ranges1, ranges2)
    if conflict:
        print(f"ERROR: Address conflict between {conflict[0]} and {conflict[1]}")
        sys.exit(1)
    
    # 合并记录（跳过结束记录）
    merged_records = []
    for record in records1 + records2:
        if record.type != 0x01:  # 跳过结束记录
            merged_records.append(record)
    
    # 生成合并后的HEX文件
    with open(output, 'w') as f:
        for record in merged_records:
            # 重新生成HEX行（简化版，实际需要计算校验和）
            if record.type == 0x04:
                data = record.data.hex().upper()
                line = f":02{record.address:04X}04{data}"
            elif record.type == 0x00:
                data = record.data.hex().upper()
                line = f":{len(record.data):02X}{record.address:04X}00{data}"
            else:
                continue  # 其他记录类型暂不处理
            
            # 计算校验和（示例实现）
            bytes_data = bytes.fromhex(line[1:])
            checksum = (-sum(bytes_data)) & 0xFF
            line += f"{checksum:02X}\n"
            f.write(line)
        
        # 添加结束记录
        f.write(":00000001FF\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Merge two HEX files with address conflict check')
    parser.add_argument('file1', help='First input HEX file')
    parser.add_argument('file2', help='Second input HEX file')
    parser.add_argument('-o', '--output', default='merged.hex', help='Output file name')
    args = parser.parse_args()
    
    merge_hex_files(args.file1, args.file2, args.output)
    print(f"Merged HEX file saved to: {args.output}")