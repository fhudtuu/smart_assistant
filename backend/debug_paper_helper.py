#!/usr/bin/env python3
"""Debug paper_helper API call"""
import sys
sys.stdout.reconfigure(encoding='utf-8')

from dotenv import load_dotenv
load_dotenv()

import os
import requests

API_KEY = os.getenv('')
API_URL = os.getenv('')

print(f"API_KEY: {API_KEY[:10] if API_KEY else None}...")
print(f"API_URL: {API_URL}")
print()

# Test with model name from paper_helper
model = ""
print(f"Testing model: '{model}'")

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

payload = {
    "model": model,
    "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Say Hi"}
    ],
    "max_tokens": 50
}

print(f"Payload model: '{payload['model']}'")
print()

try:
    resp = requests.post(API_URL, headers=headers, json=payload, timeout=30)
    result = resp.json()
    print(f"Status: {resp.status_code}")
    print(f"Response: {result}")

    if 'choices' in result:
        print("SUCCESS!")
    else:
        error = result.get('error', {})
        print(f"FAILED: {error.get('message', 'Unknown error')}")

except Exception as e:
    print(f"ERROR: {str(e)}")