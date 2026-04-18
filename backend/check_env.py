import os

# 加载环境变量
with open('.env', 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            key, value = line.split('=', 1)
            os.environ[key.strip()] = value.strip()

# 检查所有环境变量
print("所有环境变量:")
for k, v in os.environ.items():
    if '' in k or '' in k:
        print(f"  {k} = {v[:20] if len(v) > 20 else v}")
