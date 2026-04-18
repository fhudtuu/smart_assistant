#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import sys

# 第一步：加载环境变量（在导入任何模块之前）
env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env')
print(f"加载环境变量: {env_path}")

try:
    with open(env_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key.strip()] = value.strip()
    print("环境变量已加载")
except Exception as e:
    print(f"加载失败: {e}")

# 验证
print(f": {os.getenv('', 'None')[:20] if os.getenv('') else 'None'}")
print(f": {os.getenv('', 'None')}")

# 第二步：导入模块
from datasheet_rag import datasheet_rag

# 第三步：测试
print("\n=== 测试 ===")
result = datasheet_rag.ask('51单片机是什么？')
print(f"来源: {result.get('source')}")
print(f"内容长度: {len(result.get('content', ''))}")

if result.get('source') == '嵌入式助手':
    print(f"回答: {result.get('content')[:200]}")
else:
    print(f"内容: {result.get('content')}")
