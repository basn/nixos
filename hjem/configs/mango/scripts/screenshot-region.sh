#!/usr/bin/env bash
set -euo pipefail
outdir="$HOME/Pictures/Screenshots"
mkdir -p "$outdir"
out="$outdir/$(date +%Y-%m-%d_%H-%M-%S).png"
geom="$(/run/current-system/sw/bin/slurp)"
[ -n "$geom" ] || exit 0
/run/current-system/sw/bin/grim -g "$geom" "$out"
/run/current-system/sw/bin/mmsg "Screenshot saved" "$out"
