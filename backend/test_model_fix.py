#!/usr/bin/env python3
"""Test if model name fix worked"""
import sys
sys.stdout.reconfigure(encoding='utf-8')

# Read the actual model name from file
with open('paper_helper.py', 'rb') as f:
    content = f.read()

# Find the model line
lines = content.split(b'\n')
for i, line in enumerate(lines, 1):
    if b'"model":' in line:
        print(f'Line {i}: {line}')

# Now test actual API call
from dotenv import load_dotenv
load_dotenv()

import os
import requests

API_KEY = os.getenv('')
API_URL = os.getenv('')

print(f'\nAPI_KEY: {API_KEY[:10] if API_KEY else None}...')
print(f'API_URL: {API_URL}')

# Read model name from paper_helper.py
model = None
for line in lines:
    if b'"model":' in line and b'' in line:
        # Extract model name
        start = line.find(b'"model": "') + len(b'"model": "')
        end = line.find(b'"', start)
        model = line[start:end].decode('utf-8')
        break

if not model:
    # Try to find any model line
    for line in lines:
        if b'"model":' in line:
            print(f'\nFound model line: {line}')
            break

print(f'\nModel name from file: {model}')

if model:
    print(f'\nTesting API with model: {model}')

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Say Hi in one word"}
        ],
        "max_tokens": 50
    }

    try:
        resp = requests.post(API_URL, headers=headers, json=payload, timeout=30)
        result = resp.json()

        if 'choices' in result:
            content = result['choices'][0]['message']['content']
            print(f'SUCCESS! Content: {content}')
        else:
            error = result.get('error', {})
            print(f'FAILED: {error.get("message", str(result))}')
    except Exception as e:
        print(f'ERROR: {str(e)}')