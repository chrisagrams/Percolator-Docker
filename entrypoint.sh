#!/bin/sh
set -e

if [ $# -ne 2 ]; then
  echo "Usage: $0 <input.pin|input.zip> <output-directory>"
  exit 1
fi

INFILE=$1
OUT_DIR=$2

# dir where we'll put .tsv outputs
OUTTMP=$(mktemp -d)
# dir where we'll extract .zip (if any)
ZIPTMP=$(mktemp -d)

# figure out PIN_FILE
case "$INFILE" in
  *.zip|*.ZIP)
    unzip -qq "$INFILE" -d "$ZIPTMP"
    PINS=$(find "$ZIPTMP" -maxdepth 1 -type f -iname '*.pin')
    if [ -z "$PINS" ]; then
      echo "No .pin inside zip; exiting."
      exit 0
    fi
    if [ $(echo "$PINS" | wc -l) -gt 1 ]; then
      echo "Multiple .pin files in zip; please supply exactly one." >&2
      exit 1
    fi
    PIN_FILE="$PINS"
    ;;
  *.pin|*.PIN)
    PIN_FILE=$INFILE
    ;;
  *)
    echo "Input must be a .pin or .zip file." >&2
    exit 1
    ;;
esac

BASE=$(basename "$PIN_FILE" .pin)

# run Percolator, writing ONLY into $OUTTMP
/app/percolator/percolator \
    -A \
    -P rev \
    -r "$OUTTMP/peptide_fido.tsv" \
    -m "$OUTTMP/psm_fido.tsv" \
    -l "$OUTTMP/protein_fido.tsv" \
    "$PIN_FILE"

# zip up only the Percolator outputs
( cd "$OUTTMP" && zip -r "${BASE}_fido.zip" . )

# move result into the user-specified output dir
mkdir -p "$OUT_DIR"
mv "$OUTTMP/${BASE}_fido.zip" "$OUT_DIR/"

# clean up both temp dirs
rm -rf "$OUTTMP" "$ZIPTMP"
