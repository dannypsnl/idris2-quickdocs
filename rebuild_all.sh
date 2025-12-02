#!/usr/bin/env bash

set -e
set -o pipefail
set -x


idris2=${IDRIS2_EXECUTABLE:-idris2}
src_root=${IDRIS2_SRC:-$($idris2 --libdir)}
pack=${PACK_EXECUTABLE:-pack}


build_doc() {
  pkg="$1"
  mkdir -p "build/$pkg"
  $pack --with-docs install "$pkg"
  mv "$src_root/$pkg-"*"/docs/"* "build/$pkg"
  ( cd build && tar czf "${pkg}-idris2docs.tar.gz" "$pkg")
}

rm -rf build

for pkg in base contrib network prelude test; do
  build_doc "$pkg"
done

uv run ./mkindex.py build
uv run ./mkhome.py build
cp -r app.js index.html style.css build

echo "Docs build complete!"
