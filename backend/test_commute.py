#!/usr/bin/env python
import requests
import json

def test_commute_detection():
    """测试通勤助手检测"""
    test_cases = [
        ("搜索附近的咖啡店", True),
        ("你好", False),
        ("从北京到上海", True),
        ("附近的餐厅", True),
        ("今天天气怎么样", False)
    ]

    for question, expected in test_cases:
        try:
            response = requests.post(
                'http://localhost:5000/api/chat',
                json={'question': question},
                timeout=5
            )
            result = response.json()

            # 检查是否调用了通勤助手
            is_commute = result.get('source') == '通勤助手'
            status = "✓" if is_commute == expected else "✗"

            print(f"{status} '{question}'")
            print(f"  预期: {'通勤助手' if expected else 'AI模型'}")
            print(f"  实际: {result.get('source', 'Unknown')}")
            print()

        except Exception as e:
            print(f"✗ '{question}' - Error: {e}")
            print()

if __name__ == '__main__':
    test_commute_detection()