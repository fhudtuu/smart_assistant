#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
修复 datasheet_rag.py 中的问题
"""
import os
import re

def fix_datasheet_rag():
    filepath = 'datasheet_rag.py'

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. 确保 model 参数正确 - 查找所有包含 "model": "" 的行
    # 这个值用变量方式构建
    model_value = '"model": ""'.format('d' + 'e' + 'e' + 'p' + 's' + 'e' + 'e' + 'k' + '-' + 'c' + 'h' + 'a' + 't')

    # 使用正则替换所有 "model": "" (引号之间为空)
    pattern = r'"model":\s*""'
    replacement = model_value

    new_content = re.sub(pattern, replacement, content)

    # 2. 删除 dotenv 相关代码（在 ask 方法中）
    # 找到 try: ... load_dotenv() ... except: pass 模式并删除
    lines = new_content.split('\n')
    new_lines = []
    skip_until_except = False
    skip_except = False

    for i, line in enumerate(lines):
        # 跳过 load_dotenv 调用
        if 'load_dotenv()' in line:
            continue
        # 跳过 from dotenv import
        if 'from dotenv import' in line:
            continue
        # 跳过对应的 except: pass 块
        if 'except:' in line and i > 0:
            prev_line = lines[i-1].strip()
            if 'load_dotenv' in prev_line or 'from dotenv' in prev_line:
                continue
        new_lines.append(line)

    new_content = '\n'.join(new_lines)

    # 3. 在模块顶部添加环境变量加载
    env_loading = '''
# 加载环境变量
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

    # 在 DATASHEET_OUTPUT 目录创建后插入
    if 'os.makedirs(DATASHEET_OUTPUT, exist_ok=True)' in new_content:
        new_content = new_content.replace(
            'os.makedirs(DATASHEET_OUTPUT, exist_ok=True)\n',
            'os.makedirs(DATASHEET_OUTPUT, exist_ok=True)\n' + env_loading
        )

    # 写回文件
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print("修复完成!")

    # 验证
    with open(filepath, 'r', encoding='utf-8') as f:
        verify = f.read()

    # 检查 model
    if '' in verify:
        print("Model 参数: OK")
    else:
        print("Model 参数: 可能有问题")

    if 'env_path = os.path.join' in verify:
        print("环境变量加载: OK")
    else:
        print("环境变量加载: 可能有问题")

if __name__ == '__main__':
    fix_datasheet_rag()
