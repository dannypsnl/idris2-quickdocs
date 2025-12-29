#!/usr/bin/env python3

from pathlib import Path
from importlib import resources
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

    template_path = resources.files('idris2_quickdocs').joinpath('templates', 'home.md.j2')
    with template_path.open(encoding="utf-8") as f:
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
        'downloads': downloads
    }

    with open(root / 'home.html', 'w') as f:
        f.write(HTML_HEADER)
        md = tpl.render(**context)
        f.write(markdown.markdown(md))
        f.write(HTML_TRAILER)

if __name__ == '__main__':
    main()
