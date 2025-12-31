set -e
set -o pipefail
set -x
shopt -u nullglob

declare OUTDIR="$1"
shift;
mkdir -p "$OUTDIR/data"

while [[ -n "$1" ]]; do
  declare packageName="$1";
  declare docPath="$2";
  shift; shift;
  declare packageNoVersion="$(sed -E 's/^(.*)-[^-]*$/\1/' <<< "$packageName")";
  mkdir -p "$OUTDIR/data/$packageNoVersion";
  cp -r "$docPath/"* "$OUTDIR/data/$packageNoVersion";
  (cd "$docPath"; tar --transform="s,^,$packageNoVersion/," -czf "$OUTDIR/data/$packageNoVersion-idris2docs.tar.gz" *;);
done

quickdocs-mkindex    "$OUTDIR/data"
quickdocs-mkhome     "$OUTDIR/data"
quickdocs-copystatic "$OUTDIR"

echo "Docs build complete!"
