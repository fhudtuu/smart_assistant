#!/usr/bin/env python3
"""Fix paper_helper.py model name"""
import sys
sys.stdout.reconfigure(encoding='utf-8')

# Read the file
with open('paper_helper.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find and fix the model name line (line 43, index 42)
if len(lines) > 42:
    old_line = lines[42]
    print(f"Old line 43: {repr(old_line)}")

    # The correct model name for
    correct_model = ""

    # Replace empty model name with correct one
    if '"model": ""' in old_line:
        lines[42] = old_line.replace('""', f'"{correct_model}"')
        print(f"New line 43: {repr(lines[42])}")

        # Write back
        with open('paper_helper.py', 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"Fixed! Model name updated to '{correct_model}'")
    else:
        print("Line 43 doesn't match expected pattern")
        print("Current content:", repr(old_line))
else:
    print("File doesn't have enough lines")