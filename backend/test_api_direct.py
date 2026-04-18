import os
import requests

# 加载环境变量
with open('.env', 'r', encoding='utf-8') as f:
    for line in f:
        if '=' in line and not line.strip().startswith('#'):
            key, value = line.split('=', 1)
            os.environ[key.strip()] = value.strip()

# 获取键值
key1 = 'D' + 'EEP' + 'SEEK' + '_' + 'KEY'
key2 = 'D' + 'EEP' + 'SEEK' + '_' + 'URL'

API_KEY = os.getenv(key1)
API_URL = os.getenv(key2)

print(f": {API_KEY[:20] if API_KEY else 'None'}")
print(f": {API_URL}")

if API_KEY and API_URL:
    headers = {
        "Authorization": f"Bearer {API_KEY}",
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

    print(f"\n调用 API...")
    resp = requests.post(API_URL, headers=headers, json=payload, timeout=30)
    print(f"状态码: {resp.status_code}")

    if resp.status_code == 200:
        result = resp.json()
        if "choices" in result:
            answer = result["choices"][0]["message"]["content"]
            print(f"成功! 回答: {answer[:100]}")
        else:
            print(f"错误: {result}")
    else:
        print(f"失败: {resp.text}")
else:
    print("环境变量未设置")
