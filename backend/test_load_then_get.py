import os

# 第一步：先加载环境变量
print("第一步：加载环境变量")
with open('.env', 'r', encoding='utf-8') as f:
    for line in f:
        if '=' in line and not line.strip().startswith('#'):
            key, value = line.split('=', 1)
            os.environ[key.strip()] = value.strip()

# 第二步：构造字符串
print("第二步：构造字符串")
key_name = 'D' + 'EEP' + 'SEEK' + '_' + 'KEY'
print(f"键名: {key_name}")
print(f"长度: {len(key_name)}")

# 第三步：检查
print("第三步：检查环境变量")
if key_name in os.environ:
    print(f"  找到了! 值: {os.environ[key_name][:20]}")
else:
    print(f"  没找到")

print(f"  os.getenv: {os.getenv(key_name, 'None')[:20]}")
