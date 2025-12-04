#!/usr/bin/env bash

set -e
set -x
set -o pipefail
shopt -s nullglob

if [[ -z "$NOBUILD" ]]; then
    pack --with-docs build || true;
    idris2 --mkdoc;
fi

declare COMMIT="$(cat build/.idrisCommit)";

declare OUTDIR="";
for existingDir in /tmp/$COMMIT-pack-mkquickdocs-tmp-* ; do
    printf "Existing Directory, reusing...\n";
    printf "%s\n" "$existingDir";
    rm -rf "$existingDir";
    mkdir -p "$existingDir";
    OUTDIR="$existingDir";
done

if [[ -z "$OUTDIR" ]]; then
    OUTDIR="$(mktemp -d "/tmp/$COMMIT-pack-mkquickdocs-tmp-XXXXXXXXXX")";
fi
printf "%s\n" "$OUTDIR"
declare PACKPATH="${PACKPATH:-$HOME/.local/state/pack}";
declare BUILDERDIR="$(dirname "$(readlink -f "$0")")";

mkdir -p "$OUTDIR/data";

declare IPKG="$(idris2 --dump-ipkg-json)"
declare PACKAGES="$(jq -r '(.depends // [] | map(keys) | flatten | .[] // "") ' <<< "$IPKG")"
declare PACKAGENAME="$(jq -r '.name // ""' <<< "$IPKG")"

declare BUILDDIR="$(jq -r '.builddir // ""' <<< "$IPKG")"
BUILDDIR="${BUILDDIR:-build}"

copyPackageDocs() {
    declare DOCS="$1"
    declare OUTDIR_INNER="$2"
    declare PACKAGENAME_INNER="$3"
    cp -arv "$DOCS" "$OUTDIR_INNER/data/$PACKAGENAME_INNER";
    ( cd "$OUTDIR_INNER/data" && tar czf "$PACKAGENAME_INNER-idris2docs.tar.gz" "$PACKAGENAME_INNER")
}

for packageName in $PACKAGES prelude; do
    for docs in                                                       \
        "$PACKPATH/install/$COMMIT/idris2"/idris2*/$packageName*/docs \
        "$PACKPATH/install/$COMMIT/$packageName"/*/*/*/docs           ; do
        copyPackageDocs "$docs" "$OUTDIR" "$packageName";
    done
done

for docs in "$PWD/$BUILDDIR/docs" ; do
    copyPackageDocs "$docs" "$OUTDIR" "$PACKAGENAME"
done

(
    cd $BUILDERDIR;
    uv run ./mkindex.py "$OUTDIR/data"
    uv run ./mkhome.py "$OUTDIR/data"
    cp -r app.js index.html style.css $OUTDIR
)

(
    cd $OUTDIR;
    uv run python3 -m http.server 8001 || true;
)
