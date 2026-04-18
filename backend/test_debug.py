import os
from dotenv import load_dotenv

print("=== 测试 .env 加载 ===")
print(f"当前工作目录: {os.getcwd()}")
print(f".env 文件存在: {os.path.exists('.env')}")

load_dotenv(override=True)
print(f"加载后:")
print(f"- : {os.getenv('', 'None')[:10] if os.getenv('') else 'None'}")
print(f"- : {os.getenv('', 'None')}")

# 测试API调用
if os.getenv('') and os.getenv(''):
    import requests

    API_KEY = os.getenv('')
    API_URL = os.getenv('')

    print(f"\n=== 测试 API 调用 ===")
    print(f"URL: {API_URL}")
    print(f"KEY: {API_KEY[:10]}...")

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "",
        "messages": [
            {"role": "system", "content": "你是一个嵌入式工程师"},
            {"role": "user", "content": "51单片机是什么？简单回答"}
        ],
        "temperature": 0.7
    }

    try:
        resp = requests.post(API_URL, headers=headers, json=payload, timeout=30)
        print(f"状态码: {resp.status_code}")
        result = resp.json()
        print(f"响应: {result}")

        if "choices" in result and len(result["choices"]) > 0:
            answer = result["choices"][0]["message"]["content"]
            print(f"\n✅ 成功! 回答: {answer[:100]}")
        else:
            print(f"❌ 失败: {result}")
    except Exception as e:
        print(f"❌ 异常: {e}")
else:
    print("❌ 环境变量未加载")
