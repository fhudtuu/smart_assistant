import os

# 先设置环境变量
test_key = 'TEST' + '_KEY'
test_value = 'test_value_123'
os.environ[test_key] = test_value

print(f"1. 设置前: {os.getenv(test_key)}")

# 导入模块
from datasheet_rag import datasheet_rag

print(f"2. 导入后: {os.getenv(test_key)}")

# 检查模块中的环境变量加载逻辑
print(f"3. 模块初始化消息应该在上方")

# 测试
result = datasheet_rag.ask('51单片机是什么？')
print(f"4. 结果来源: {result.get('source')}")
