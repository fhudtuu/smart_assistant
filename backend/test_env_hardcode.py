#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os

# 加载环境变量
env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env')
print(f"加载: {env_path}")

with open(env_path, 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            key, value = line.split('=', 1)
            os.environ[key.strip()] = value.strip()

# 验证
print("验证:")
print(f": {os.getenv('', 'None')[:15]}...")
print(f": {os.getenv('', 'None')}")

# 测试 API
if os.getenv('') and os.getenv(''):
    import requests
    headers = {
        "Authorization": f"Bearer {os.getenv('')}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "",
        "messages": [
            {"role": "system", "content": "你是一个嵌入式工程师"},
            {"role": "user", "content": "51单片机是什么？"}
        ],
        "temperature": 0.7
    }

    print("\n测试 API 调用...")
    resp = requests.post(os.getenv(''), headers=headers, json=payload, timeout=30)
    print(f"状态码: {resp.status_code}")

    if resp.status_code == 200:
        result = resp.json()
        if "choices" in result:
            answer = result["choices"][0]["message"]["content"]
            print(f"✅ 成功! 回答: {answer[:100]}")
        else:
            print(f"❌ 错误: {result}")
    else:
        print(f"❌ 失败: {resp.text}")
else:
    print("❌ 环境变量未加载")
