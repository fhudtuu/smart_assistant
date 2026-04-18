import os

print("=== 手动加载 .env 文件 ===")

try:
    with open('.env', 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key.strip()] = value.strip()
                if '' in key or '' in key:
                    print(f"{key} = {value[:30] if len(value) > 30 else value}...")

    print(f"\n验证:")
    print(f"- : {os.getenv('', 'NOT_FOUND')[:20]}")
    print(f"- : {os.getenv('', 'NOT_FOUND')}")

except Exception as e:
    print(f"错误: {e}")
