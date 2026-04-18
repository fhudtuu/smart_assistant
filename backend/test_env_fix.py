#!/usr/bin/env python3
"""Test environment variable loading"""
import sys
sys.stdout.reconfigure(encoding='utf-8')

from dotenv import load_dotenv
load_dotenv()

import os

# Try different ways to access environment variables
print("Method 1: Direct string literal")
try:
    key1 = os.getenv('')
    url1 = os.getenv('')
    print(f"  : {key1[:10] if key1 else None}...")
    print(f"  : {url1}")
except Exception as e:
    print(f"  Error: {e}")

print("\nMethod 2: Read from .env file directly")
try:
    with open('.env', 'r', encoding='utf-8') as f:
        for line in f:
            if line.startswith('='):
                key2 = line.split('=', 1)[1].strip()
                print(f"  Key: {key2[:10]}...")
            elif line.startswith('='):
                url2 = line.split('=', 1)[1].strip()
                print(f"  URL: {url2}")
except Exception as e:
    print(f"  Error: {e}")

print("\nMethod 3: Check os.environ")
try:
    if '' in os.environ:
        key3 = os.environ['']
        print(f"  : {key3[:10]}...")
    if '' in os.environ:
        url3 = os.environ['']
        print(f"  : {url3}")
except Exception as e:
    print(f"  Error: {e}")