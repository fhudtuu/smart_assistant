#!/usr/bin/env python3
"""Fix model name in paper_helper.py"""
import sys
sys.stdout.reconfigure(encoding='utf-8')

# The correct model name for
# This is the official model name from
correct_model = ""  # This will be set to the correct value

# Read paper_helper.py
with open('paper_helper.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the model_name variable and payload model
# Replace empty strings with the correct model name
# The correct :

# Read the actual value from index.py which works correctly
try:
    with open('index.py', 'r', encoding='utf-8') as f:
        for line in f:
            if '' in line:
                print(f"Found in index.py: {line.strip()}")
                break
except:
    pass

# For now, use the known correct model name
correct_model = ""  # 's official chat model

# Fix the content
lines = content.split('\n')
new_lines = []
for line in lines:
    if 'model_name = ""' in line:
        new_lines.append(f'    model_name = "{correct_model}"')
        print(f"Fixed model_name")
    elif '"model": os.getenv("", "")' in line:
        new_lines.append(f'        "model": "{correct_model}",')
        print(f"Fixed payload model")
    else:
        new_lines.append(line)

# Write back
with open('paper_helper.py', 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))

print("Model name fixed!")
