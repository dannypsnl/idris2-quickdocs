#!/usr/bin/env bash

set -e
set -o pipefail
set -x


idris2=${IDRIS2_EXECUTABLE:-idris2}
src_root=${IDRIS2_SRC:-$($idris2 --libdir)}
pack=${PACK_EXECUTABLE:-pack}



build_doc() {
  pkg="$1"
  mkdir -p "build/data/$pkg"
  rm -rf "$src_root/$pkg-"*"/docs/" 
  $pack --with-docs install "$pkg"
  cp -arv "$src_root/$pkg-"*"/docs/"* "build/data/$pkg"
  ( cd build/data && tar czf "${pkg}-idris2docs.tar.gz" "$pkg")
}

rm -rf build
mkdir -p "build/data/"

for pkg in base contrib network prelude test; do
  build_doc "$pkg"
done

uv run ./mkindex.py build/data
uv run ./mkhome.py build/data
cp -r app.js index.html style.css build

echo "Docs build complete!"
