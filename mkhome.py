#!/usr/bin/env python3

from pathlib import Path
from subprocess import check_output
import sys

from jinja2 import Template
import markdown

HTML_HEADER = ''' <!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>Idris2 Docs</title><link rel="stylesheet" href="../style.css"></head><body class="nodebug"><article class="copy">
'''
HTML_TRAILER = '''</article></body></html>'''

def main():
    root = Path(sys.argv[1])
    idris_src_root = Path(sys.argv[2])

    idris_src_version = check_output(["git", "describe", "--tags"], cwd=idris_src_root, encoding='utf-8').strip()
    idris_commit_id = check_output(["git", "rev-list", "--max-count=1", "HEAD"], cwd=idris_src_root, encoding='utf-8').strip()

    with open('templates/home.md.j2') as f:
        tpl = Template(f.read())

    packages = []
    downloads = []
    for pkg in sorted(root.glob('*/index.html')):
        link = pkg.relative_to(root)
        pkg = link.parts[-2]
        packages.append(pkg)
        dlfilename = pkg + '-idris2docs.tar.gz'
        downloads.append(dlfilename)

    context = {
        'packages': packages,
        'downloads': downloads,
        'idris_src_version': idris_src_version,
        'idris_commit_id': idris_commit_id,
    }

    with open(root / 'home.html', 'w') as f:
        f.write(HTML_HEADER)
        md = tpl.render(**context)
        f.write(markdown.markdown(md))
        f.write(HTML_TRAILER)

if __name__ == '__main__':
    main()
