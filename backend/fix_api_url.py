#!/usr/bin/env python3
"""Fix API URL in paper_helper.py"""
import sys
sys.stdout.reconfigure(encoding='utf-8')

# Read the .env file to get the correct URL
with open('.env', 'r', encoding='utf-8') as f:
    for line in f:
        # Find
        if line.startswith('='):
            parts = line.strip().split('=', 1)
            if len(parts) == 2:
                correct_url = parts[1]
                print(f"Found : {correct_url}")

                # Now update paper_helper.py
                with open('paper_helper.py', 'r', encoding='utf-8') as f2:
                    content = f2.read()

                # Find the API_URL line and replace
                lines = content.split('\n')
                new_lines = []
                for line in lines:
                    if 'API_URL =' in line and ('https://' in line or 'sk-' in line):
                        new_lines.append(f'    API_URL = "{correct_url}"')
                        print(f"Updated line: API_URL = {correct_url}")
                    else:
                        new_lines.append(line)

                with open('paper_helper.py', 'w', encoding='utf-8') as f2:
                    f2.write('\n'.join(new_lines))

                print("Fixed paper_helper.py!")
                break
