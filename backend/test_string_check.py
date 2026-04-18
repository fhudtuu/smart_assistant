import os

# 测试字符串
test_str = ''
print(f"字符串: '{test_str}'")
print(f"长度: {len(test_str)}")
print(f"repr: {repr(test_str)}")

# 加载环境变量
with open('.env', 'r', encoding='utf-8') as f:
    for line in f:
        if '=' in line and not line.strip().startswith('#'):
            key, value = line.split('=', 1)
            os.environ[key.strip()] = value.strip()

# 检查
result = os.getenv(test_str)
print(f"结果: {result}")
