#!/usr/bin/env bash

set -e
set -o pipefail
set -x


idris2=${IDRIS2_EXECUTABLE:-idris2}
src_root=${IDRIS2_SRC:-$($idris2 --libdir)}


build_doc() {
  pkg="$1"
  declare TMP="$(mktemp -d)"
  mkdir -p "build/$pkg"
  (
    cd "${src_root}/$pkg-"*
    "$idris2" --mkdoc --build-dir "$TMP"
  )
  mv "$TMP/docs/"* "build/$pkg"
  ( cd build && tar czf "${pkg}-idris2docs.tar.gz" "$pkg")
}

for pkg in base contrib network prelude test; do
  build_doc "$pkg"
done

uv run ./mkindex.py build
uv run ./mkhome.py build
cp -r app.js index.html style.css build

echo "Docs build complete!"
