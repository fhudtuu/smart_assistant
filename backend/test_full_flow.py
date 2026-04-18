#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
测试完整的 API 调用流程
"""
import os
import sys

# 加载环境变量
with open('.env', 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            key, value = line.split('=', 1)
            os.environ[key.strip()] = value.strip()

print("环境变量已加载")
print(f": {bool(os.getenv(''))}")
print(f": {bool(os.getenv(''))}")

# 导入模块
from datasheet_rag import datasheet_rag

# 测试
print("\n测试 ask 方法...")
result = datasheet_rag.ask('51单片机')

print(f"\n结果来源: {result.get('source')}")
print(f"内容长度: {len(result.get('content', ''))}")

if result.get('source') == '嵌入式助手':
    print("\n成功! 回答内容:")
    print(result.get('content')[:200])
else:
    print(f"\n失败: {result.get('content')}")
