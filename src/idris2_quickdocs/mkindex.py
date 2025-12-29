#!/usr/bin/env python3

import json
from pathlib import Path
import re
import traceback
from typing import NamedTuple

from bs4 import BeautifulSoup

class IndexEntry(NamedTuple):
    name: str
    namespace: str
    package: str
    target: str

RE_NAMESPACE = re.compile(r"""(?P<ns>([^.]+\.)+)(?P<name>.+)""")
def split_ns(full_name):
    match = RE_NAMESPACE.match(full_name)
    return match.group('ns')[:-1], match.group('name')

def sortkey(x):
    return (x.name.lower(),
            x.namespace.lower(),
            x.package.lower(),
            x.target
            )

class IndexBuilder:
    def __init__(self, root: str):
        self.root = Path(root)
        self.entries = []

    def run(self):
        sources = self.root.glob('**/*.html')

        for source in sources:
            try:
                self.scan(source)
            except Exception as e:
                print(f"error processing file {source}")
                traceback.print_exc()

        self.entries.sort(key=sortkey)
        with open(self.root / 'index.json', 'w') as f:
            json.dump(self.entries, f)

    def scan(self, source):
        entries = []
        relpath = source.relative_to(self.root)
        package = relpath.parts[0]
        print(f"scanning {source}")

        with open(source) as f:
            soup = BeautifulSoup(f, 'html.parser')

        docclass = soup.find('body')['class']
        if 'namespace' not in docclass:
            return

        namespace = soup.select('h1')[0].get_text(strip=True)

        for dt in soup.select('dl.decls > dt'):
            id = dt['id']
            if id.startswith('$resolved'):
                continue
            span = dt.select('span.name')[0]
            name = span.get_text(strip=True)
            entries.append(IndexEntry(
                name,
                namespace,
                package,
                relpath.as_posix() + '#' + id
            ))
        self.entries += entries

def main():
    import sys
    builder = IndexBuilder(sys.argv[1])
    builder.run()

if __name__ == '__main__':
    main()
