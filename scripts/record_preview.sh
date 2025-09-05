#!/bin/bash
# Record an App Store–ready App Preview from the iOS/iPadOS Simulator.
# Defaults: iPhone + portrait + muted.
#
# Usage:
#   ./record_preview.sh                               # iPhone portrait, muted
#   ./record_preview.sh --unmute                      # iPhone portrait, AAC audio
#   ./record_preview.sh --landscape                   # iPhone landscape, muted
#   ./record_preview.sh --device ipad                 # iPad portrait, muted
#   ./record_preview.sh --device ipad --landscape --unmute --max30s

set -euo pipefail

# ---- defaults
DEVICE="iphone"      # iphone | ipad
MODE="portrait"      # portrait | landscape
MUTE=1               # 1 = muted, 0 = keep audio (AAC)
MAX30=0              # 1 = trim to 30s

# ---- parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)    DEVICE="${2:-}"; shift 2;;
    --portrait)  MODE="portrait"; shift;;
    --landscape) MODE="landscape"; shift;;
    --mute)      MUTE=1; shift;;
    --unmute)    MUTE=0; shift;;
    --max30s)    MAX30=1; shift;;
    -h|--help)
      echo "Usage: $0 [--device iphone|ipad] [--portrait|--landscape] [--mute|--unmute] [--max30s]"
      exit 0;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

# ---- dimensions per Apple App Preview spec
case "${DEVICE}:${MODE}" in
  iphone:portrait)   W=886;  H=1920;;
  iphone:landscape)  W=1920; H=886;;
  ipad:portrait)     W=1200; H=1600;;
  ipad:landscape)    W=1600; H=1200;;
  *) echo "Invalid combination DEVICE='${DEVICE}' MODE='${MODE}'"; exit 1;;
esac

RAW="app_preview_raw.mov"
OUT="app_preview_${DEVICE}_${W}x${H}.mov"

# ---- ensure a simulator is booted
if ! xcrun simctl list devices booted | grep -q "Booted"; then
  echo "No Simulator is booted. Open one (e.g., iPhone 16 Pro Max) and try again."
  exit 1
fi

echo "Recording from Simulator (${DEVICE}, ${MODE})… press Ctrl+C when finished."
xcrun simctl io booted recordVideo --codec=h264 --force "$RAW"

# ---- optional trim to 30s
declare -a TRIM_ARGS=()
if [[ "$MAX30" -eq 1 ]]; then
  TRIM_ARGS=(-t 00:00:30)
fi

# ---- audio settings
declare -a AUDIO_ARGS=()
if [[ "$MUTE" -eq 1 ]]; then
  AUDIO_ARGS=(-an)
else
  AUDIO_ARGS=(-c:a aac -b:a 128k -ar 44100 -ac 2)
fi

# ---- scale (ratio-aware) + center crop → exact dimensions
VF="scale='if(gt(a,${W}/${H}),-2,${W})':'if(gt(a,${W}/${H}),${H},-2)',crop=${W}:${H}"

echo "Processing to ${W}x${H} (mute=${MUTE}, max30s=${MAX30})…"
ffmpeg -y -i "$RAW" \
  -vf "$VF" \
  -r 30 -vsync cfr \
  "${TRIM_ARGS[@]+"${TRIM_ARGS[@]}"}" \
  -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -crf 18 -preset slow \
  "${AUDIO_ARGS[@]+"${AUDIO_ARGS[@]}"}" \
  -movflags +faststart \
  "$OUT"

echo "Done: $OUT"
echo "Tip: Validate with: ffprobe -v error -show_streams -show_format \"$OUT\""
