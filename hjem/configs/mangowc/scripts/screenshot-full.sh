#!/usr/bin/env bash
set -euo pipefail
outdir="$HOME/Pictures/Screenshots"
mkdir -p "$outdir"
out="$outdir/$(date +%Y-%m-%d_%H-%M-%S).png"
/run/current-system/sw/bin/grim "$out"
/run/current-system/sw/bin/mmsg "Screenshot saved" "$out"
