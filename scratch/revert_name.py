import os

def replace_in_file(path, replacements):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return
    
    new_content = content
    for old, new in replacements:
        new_content = new_content.replace(old, new)
        
    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {path}")

replacements = [
    ('primkopasindo_labojon', 'hadirin'),
    ('Primkopasindo Labojon', 'Hadir.in'),
    ('com.primkopasindo.labojon', 'com.mobile.hadirin'),
    ('LABOJON', 'Hadir.in')
]

for root, dirs, files in os.walk('.'):
    if '.git' in root or 'node_modules' in root or 'build' in root or 'scratch' in root:
        continue
    for file in files:
        if file.endswith(('.dart', '.yaml', '.xml', '.plist', '.pbxproj', '.xcconfig', '.kts', '.kt', '.html', '.gs', '.md', '.json', '.txt')):
            path = os.path.join(root, file)
            replace_in_file(path, replacements)
