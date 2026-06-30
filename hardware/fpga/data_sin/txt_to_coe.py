import os

def txt_to_coe(input_filename, output_filename, bit_width=16):
    """
    将包含有符号十进制整数的txt文件转换为Vivado的coe文件 (Radix=16)。
    """
    
    # 检查输入文件是否存在
    if not os.path.exists(input_filename):
        print(f"错误: 找不到文件 {input_filename}")
        return

    print(f"正在读取 {input_filename} ...")
    
    data_list = []
    
    try:
        with open(input_filename, 'r') as f:
            lines = f.readlines()
            
            for line in lines:
                line = line.strip()
                if not line:
                    continue # 跳过空行
                
                try:
                    val = int(line)
                    
                    # 将有符号整数转换为指定位宽的补码十六进制
                    # mask = 0xFFFF (对于16位)
                    mask = (1 << bit_width) - 1
                    hex_val = "{:0{width}X}".format(val & mask, width=bit_width//4)
                    
                    data_list.append(hex_val)
                    
                except ValueError:
                    print(f"警告: 跳过非数字行: '{line}'")

    except Exception as e:
        print(f"读取文件时发生错误: {e}")
        return

    if not data_list:
        print("错误: 没有提取到有效数据。")
        return

    print(f"提取到 {len(data_list)} 个数据，正在写入 {output_filename} ...")

    # 写入COE文件
    with open(output_filename, 'w') as f:
        # 写入Header
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        
        # 写入数据
        # Vivado要求数据用逗号分隔，最后一个数据后跟分号
        for i, hex_data in enumerate(data_list):
            if i == len(data_list) - 1:
                f.write(f"{hex_data};\n")  # 最后一个数据用分号结尾
            else:
                f.write(f"{hex_data},\n")  # 其他数据用逗号分隔

    print("转换完成！")

if __name__ == "__main__":
    # 配置输入输出文件名
    input_file = 'din_fixed.txt'
    output_file = 'din_fixed.coe'
    
    # 你的数据最大约26000，适合16位宽
    txt_to_coe(input_file, output_file, bit_width=16)