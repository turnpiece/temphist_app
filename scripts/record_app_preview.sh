#!/bin/bash
# record_preview.sh
# Usage: ./record_preview.sh portrait|landscape [--max30s]

set -euo pipefail

MODE=${1:-}
MAX30=${2:-}

if [[ "$MODE" == "portrait" ]]; then
  W=886; H=1920; OUT="tempHist_preview_886x1920.mov"
  # If source is "wider" than target (a > W/H), scale by height; else scale by width.
  VF="scale='if(gt(a,${W}/${H}),-2,${W})':'if(gt(a,${W}/${H}),${H},-2)',crop=${W}:${H}"
elif [[ "$MODE" == "landscape" ]]; then
  W=1920; H=886; OUT="tempHist_preview_1920x886.mov"
  VF="scale='if(gt(a,${W}/${H}),-2,${W})':'if(gt(a,${W}/${H}),${H},-2)',crop=${W}:${H}"
else
  echo "Usage: $0 portrait|landscape [--max30s]"
  exit 1
fi

RAW="tempHist_preview_raw.mov"

echo "Recording in $MODE … press Ctrl+C to stop."
xcrun simctl io booted recordVideo --codec=h264 --force "$RAW"

# Optional 30s cap
TRIM_ARGS=()
if [[ "$MAX30" == "--max30s" ]]; then
  TRIM_ARGS=(-t 00:00:30)
fi

echo "Processing → ${W}x${H}…"
ffmpeg -y -i "$RAW" \
  -vf "$VF" \
  "${TRIM_ARGS[@]}" \
  -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -movflags +faststart \
  -c:a aac -b:a 128k \
  "$OUT"

echo "Done: $OUT"
