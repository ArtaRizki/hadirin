
import os
import re

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Fix withOpacity
    new_content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)
    
    # Fix onPopInvoked
    new_content = new_content.replace('onPopInvoked: (didPop) {', 'onPopInvokedWithResult: (didPop, result) {')
    new_content = new_content.replace('onPopInvoked: (didPop) async {', 'onPopInvokedWithResult: (didPop, result) async {')
    
    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed {path}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))
