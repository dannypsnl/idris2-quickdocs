#!/usr/bin/env python3

from pathlib import Path
from importlib import resources
from shutil import copytree
import sys

def main():
    f = resources.files('idris2_quickdocs');
    copytree(f.joinpath('static'),Path(sys.argv[1]), dirs_exist_ok=True);

if __name__ == "__main__":
    main();
