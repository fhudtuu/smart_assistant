#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
完整修复 datasheet_rag.py 的所有问题
"""
import re

def fix_all():
    filepath = 'datasheet_rag.py'

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. 修复 model 参数
    content = re.sub(r'"model":\s*""', '"model": ""', content)

    # 2. 删除 dotenv 代码块（467-471行）
    # 找到并删除 try: ... load_dotenv() ... except: pass
    pattern = r'''        try:\s*
            from dotenv import load_dotenv\s*
            load_dotenv\(\)\s*
        except:\s*
            pass\s*
\s*'''
    content = re.sub(pattern, '', content)

    # 3. 添加环境变量加载（在文件顶部）
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

    # 在 DATASHEET_OUTPUT 创建后插入
    if 'os.makedirs(DATASHEET_OUTPUT, exist_ok=True)' in content:
        content = content.replace(
            'os.makedirs(DATASHEET_OUTPUT, exist_ok=True)\n\n',
            'os.makedirs(DATASHEET_OUTPUT, exist_ok=True)\n' + env_loading + '\n'
        )

    # 写回文件
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    print("✅ 修复完成!")

    # 验证
    with open(filepath, 'r', encoding='utf-8') as f:
        verify = f.read()

    model_ok = '' in verify
    env_ok = 'env_path = os.path.join' in verify
    no_dotenv = 'load_dotenv' not in verify

    print(f"Model 参数: {'✅' if model_ok else '❌'}")
    print(f"环境变量加载: {'✅' if env_ok else '❌'}")
    print(f"删除 dotenv: {'✅' if no_dotenv else '❌'}")

if __name__ == '__main__':
    fix_all()
