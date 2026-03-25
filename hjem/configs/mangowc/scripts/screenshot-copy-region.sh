#!/usr/bin/env bash
set -euo pipefail
geom="$(/run/current-system/sw/bin/slurp)"
[ -n "$geom" ] || exit 0
/run/current-system/sw/bin/grim -g "$geom" - | /run/current-system/sw/bin/wl-copy
/run/current-system/sw/bin/mmsg "Screenshot copied" "Region copied to clipboard"
