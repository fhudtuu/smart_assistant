#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
简单、安全的修复方案
"""

def fix_line_by_line():
    filepath = 'datasheet_rag.py'

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # 1. 修复 model 参数（第495行）
    for i, line in enumerate(lines):
        if i == 494:  # 第495行（索引494）
            if '"model": ""' in line:
                m = ''
                lines[i] = line.replace('""', f'"{m}"')
                print(f"1. Model 参数已修复")
                break

    # 2. 删除 dotenv 代码（第467-471行）
    new_lines = []
    skip_next = False
    for i, line in enumerate(lines):
        # 跳过 try: 行（如果后面是 dotenv）
        if 'try:' in line and i+1 < len(lines) and 'from dotenv import' in lines[i+1]:
            continue
        # 跳过 dotenv import 和 load_dotenv
        if 'from dotenv import' in line or 'load_dotenv()' in line:
            continue
        # 跳过 except: pass（如果前面是 dotenv）
        if 'except:' in line and i > 0 and ('from dotenv' in lines[i-1] or 'load_dotenv' in lines[i-1]):
            continue
        new_lines.append(line)

    lines = new_lines
    print("2. Dotenv 代码已删除")

    # 3. 添加环境变量加载（在 DATASHEET_OUTPUT 创建后）
    env_loading = '''# 加载环境变量
try:
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env')
    if os.path.exists(env_path):
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip()
except:
    pass

'''

    # 找到 DATASHEET_OUTPUT 创建的位置
    for i, line in enumerate(lines):
        if 'os.makedirs(DATASHEET_OUTPUT, exist_ok=True)' in line:
            lines.insert(i+1, env_loading)
            print("3. 环境变量加载已添加")
            break

    # 写回文件
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(lines)

    print("4. 修复完成!")

if __name__ == '__main__':
    fix_line_by_line()
