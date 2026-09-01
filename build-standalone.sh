#!/bin/bash
# Builds luke-standalone.html — ONE file with photos embedded as base64.
# Re-run this after any edit to index.html.
set -euo pipefail
cd "$(dirname "$0")"
python3 - <<'PY'
from PIL import Image
import base64, io, re, os
h = open('index.html').read()
data = {}
for i in range(1, 7):
    p = f'photos/luke-{i}.jpg'
    if not os.path.exists(p):
        continue
    im = Image.open(p).convert('RGB')
    im.thumbnail((900, 1200), Image.LANCZOS)          # shrink for email/AirDrop
    buf = io.BytesIO(); im.save(buf, 'JPEG', quality=82, optimize=True)
    data[i] = 'data:image/jpeg;base64,' + base64.b64encode(buf.getvalue()).decode()
js = 'const PHOTO_DATA={' + ','.join(f'{k}:"{v}"' for k, v in data.items()) + '};\n'
h = h.replace('const CAPTIONS', js + 'const CAPTIONS', 1)
tag_src = 'src="photos/luke-${n}.jpg"'
assert tag_src in h, 'gallery img src pattern not found'
h = h.replace(tag_src, 'src="${PHOTO_DATA[n]||\'\'}"')

# inline three.js so the single file keeps its 3D with no network
three = open('vendor/three.min.js').read()
tag = '<script src="vendor/three.min.js"></script>'
assert tag in h, 'three.js script tag not found'
h = h.replace(tag, '<script>' + three + '</script>', 1)

open('luke-standalone.html', 'w').write(h)
print(f'embedded {len(data)} photos')
PY
ls -lh luke-standalone.html | awk '{print "luke-standalone.html  "$5}'
