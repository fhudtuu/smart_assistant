#!/usr/bin/env python3
"""Fix index.py - construct correct lines using bytes"""
import sys
sys.stdout.reconfigure(encoding='utf-8')

# Read current content
with open('index.py', 'rb') as f:
    data = f.read()

lines = data.split(b'\n')

# Show current lines 26-29
for i in range(25, 30):
    print(f"L{i+1}: {lines[i]}")
