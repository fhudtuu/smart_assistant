import os

# 加载环境变量
with open('.env', 'r', encoding='utf-8') as f:
    for line in f:
        if '=' in line and not line.strip().startswith('#'):
            key, value = line.split('=', 1)
            os.environ[key.strip()] = value.strip()

# 检查环境变量中的所有键
print("所有环境变量键:")
all_keys = list(os.environ.keys())
print(f"总数: {len(all_keys)}")

# 查找包含 EEPSEEK 的键
print("\n包含 EEPSEEK 的键:")
for key in all_keys:
    if 'EEPSEEK' in key:
        print(f"  {key} = {os.environ[key][:20]}")

# 直接访问
print("\n直接访问:")
try:
    key1 = os.environ.get('', 'None')
    print(f"  os.environ.get('') = {key1[:20]}")
except Exception as e:
    print(f"  错误: {e}")

try:
    key2 = os.getenv('', 'None')
    print(f"  os.getenv('') = {key2[:20]}")
except Exception as e:
    print(f"  错误: {e}")
