#!/usr/bin/env bash

set -e
set -u
set -o pipefail
set -x

src_root=${IDRIS2_SRC:-$PWD/../Idris2-vanilla}
idris2=${IDRIS2_EXECUTABLE:-idris2}

build_doc() {
  pkg="$1"
  (
    cd "${src_root}/libs/$pkg"
    rm -rf build/docs
    "$idris2" --mkdoc "${pkg}.ipkg"
  )

  rm -rf "data/${pkg}"

  mkdir -p data
  cp -av "${src_root}/libs/${pkg}/build/docs" "data/${pkg}"
  ( cd data && tar czf "${pkg}-idris2docs.tar.gz" "$pkg")
}

for pkg in base contrib network prelude test; do
  build_doc "$pkg"
done

poetry run ./mkindex.py data
poetry run ./mkhome.py data "$src_root"

echo "Docs build complete, documented Idris2 version:"
(cd "$src_root" && git describe --tags)
