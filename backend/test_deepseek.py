#!/usr/bin/env python3
"""Test """
import os
import sys
import requests
from dotenv import load_dotenv

def test_deepseek_api():
    load_dotenv()

    API_KEY = os.getenv('')
    API_URL = os.getenv('')

    print(f"API_URL: {API_URL}")
    print(f"API_KEY: {API_KEY[:10]}..." if API_KEY else "No API_KEY")
    print()

    if not API_KEY or not API_URL:
        print("ERROR: Missing ")
        return False

    # Test with correct model name
    model = ""
    print(f"Testing model: {model}")

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Say 'Hello, !' in one sentence."}
        ],
        "max_tokens": 50
    }

    try:
        resp = requests.post(API_URL, headers=headers, json=payload, timeout=30)
        result = resp.json()

        print(f"Status Code: {resp.status_code}")
        print(f"Response keys: {list(result.keys())}")

        if 'choices' in result and len(result['choices']) > 0:
            content = result['choices'][0]['message']['content']
            print(f"\n✅ SUCCESS!")
            print(f"Generated content: {content}")
            return True
        else:
            print(f"\n❌ FAILED!")
            print(f"Error: {result}")
            return False

    except Exception as e:
        print(f"\n❌ EXCEPTION: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_deepseek_api()
    sys.exit(0 if success else 1)