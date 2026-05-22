import os
import re


def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace .withOpacity(x) with .withValues(alpha: x)
    new_content = re.sub(
        r'\.withOpacity\(([^)]+)\)',
        r'.withValues(alpha: \1)',
        content
    )

    # Replace .value on Color objects (rudimentary) - actually it's easier to
    # just do it via regex
    # Wait, the warning says "'value' is deprecated and shouldn't be used.
    # Use component accessors like .r or .g, or toARGB32 for an explicit
    # conversion."
    # We should replace `.value` with `.toARGB32()` where it makes sense,
    # but we only have a few cases.

    # Remove unused dart:typed_data
    new_content = re.sub(r"import 'dart:typed_data';\n", "", new_content)

    if content != new_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")


for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
