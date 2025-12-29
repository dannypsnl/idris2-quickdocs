set -e
set -o pipefail
set -x
shopt -u nullglob

declare OUTDIR="$1"
shift;
mkdir -p "$OUTDIR/data"


for p in "$@"; do
  declare packageName="$(basename "$p/share/doc/"*)";
  declare DOCS="$p/share/doc/"
  declare packageNoVersion="$(sed -E 's/^(.*)-[^-]*$/\1/' <<< "$packageName")";
  mkdir -p "$OUTDIR/data/$packageNoVersion";
  cp -r "$DOCS/$packageName/"* "$OUTDIR/data/$packageNoVersion";
  (cd "$DOCS"; tar czf "$OUTDIR/data/$packageNoVersion-idris2docs.tar.gz" "$packageName";);
done

quickdocs-mkindex    "$OUTDIR/data"
quickdocs-mkhome     "$OUTDIR/data"
quickdocs-copystatic "$OUTDIR"

echo "Docs build complete!"
