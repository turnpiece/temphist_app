#!/bin/bash
# Record an App Store–ready App Preview from the iOS/iPadOS Simulator.
# Defaults: iPhone + portrait + silent AAC audio + 30s max duration.
#
# Usage:
#   ./record_preview.sh                               # iPhone portrait, silent AAC, ≤30s
#   ./record_preview.sh --unmute                      # iPhone portrait, mic audio (AAC), ≤30s
#   ./record_preview.sh --landscape                   # iPhone landscape
#   ./record_preview.sh --device ipad                 # iPad portrait
#   ./record_preview.sh --no-max30s                   # don’t trim (keeps full length)

set -euo pipefail

# ---- defaults
DEVICE="iphone"      # iphone | ipad
MODE="portrait"      # portrait | landscape
UNMUTE=0             # 1 = keep captured audio (AAC), 0 = add silent AAC
MUTE_HARD=0          # 1 = remove audio track entirely
MAX30=1              # default: trim to 30s

# ---- parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)    DEVICE="${2:-}"; shift 2;;
    --portrait)  MODE="portrait"; shift;;
    --landscape) MODE="landscape"; shift;;
    --unmute)    UNMUTE=1; shift;;
    --mute-hard) MUTE_HARD=1; shift;;
    --no-max30s) MAX30=0; shift;;
    -h|--help)
      echo "Usage: $0 [--device iphone|ipad] [--portrait|--landscape] [--unmute] [--mute-hard] [--no-max30s]"
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

# ---- optional trim
declare -a TRIM_ARGS=()
if [[ "$MAX30" -eq 1 ]]; then
  TRIM_ARGS=(-t 00:00:30)
fi

# ---- video filter: ratio-aware scale + center crop → exact dimensions
VF="scale='if(gt(a,${W}/${H}),-2,${W})':'if(gt(a,${W}/${H}),${H},-2)',crop=${W}:${H}"

# ---- audio handling
declare -a AUDIO_INPUT_ARGS=()
declare -a AUDIO_OUTPUT_ARGS=()

if [[ "$MUTE_HARD" -eq 1 ]]; then
  AUDIO_OUTPUT_ARGS=(-an)
elif [[ "$UNMUTE" -eq 1 ]]; then
  AUDIO_OUTPUT_ARGS=(-c:a aac -b:a 128k -ar 44100 -ac 2)
else
  AUDIO_INPUT_ARGS=(-f lavfi -t 9999 -i anullsrc=channel_layout=mono:sample_rate=44100)
  AUDIO_OUTPUT_ARGS=(-shortest -c:a aac -b:a 96k -ar 44100 -ac 1)
fi

echo "Processing to ${W}x${H} (unmute=${UNMUTE}, mute-hard=${MUTE_HARD}, max30s=${MAX30})…"
if [[ "$MUTE_HARD" -eq 1 || "$UNMUTE" -eq 1 ]]; then
  ffmpeg -y -i "$RAW" \
    -vf "$VF" \
    -r 30 -vsync cfr \
    "${TRIM_ARGS[@]+"${TRIM_ARGS[@]}"}" \
    -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -crf 18 -preset slow \
    "${AUDIO_OUTPUT_ARGS[@]+"${AUDIO_OUTPUT_ARGS[@]}"}" \
    -movflags +faststart \
    "$OUT"
else
  ffmpeg -y -i "$RAW" "${AUDIO_INPUT_ARGS[@]}" \
    -map 0:v:0 -map 1:a:0 \
    -vf "$VF" \
    -r 30 -vsync cfr \
    "${TRIM_ARGS[@]+"${TRIM_ARGS[@]}"}" \
    -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -crf 18 -preset slow \
    "${AUDIO_OUTPUT_ARGS[@]+"${AUDIO_OUTPUT_ARGS[@]}"}" \
    -movflags +faststart \
    "$OUT"
fi

echo "Done: $OUT"
echo "Validating with ffprobe…"

# --- show key info
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height,pix_fmt,r_frame_rate -of default=nw=1:nk=1 "$OUT"
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels -of default=nw=1:nk=1 "$OUT" || true

# --- compliance checks
echo "Running basic compliance checks…"
fail=0
vw=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$OUT" || echo 0)
vh=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$OUT" || echo 0)
[[ "$vw" == "$W" && "$vh" == "$H" ]] || { echo "❌ Wrong dimensions ${vw}x${vh}, expected ${W}x${H}"; fail=1; }
pf=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of csv=p=0 "$OUT" || echo "")
[[ "$pf" == "yuv420p" ]] || { echo "❌ Pixel format not yuv420p (got '$pf')"; fail=1; }
dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT" | cut -d. -f1 || echo 0)
[[ "$dur" -le 30 ]] || { echo "❌ Duration ${dur}s exceeds 30s"; fail=1; }
acodec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$OUT" || echo "")
if [[ "$MUTE_HARD" -eq 0 && "$acodec" != "aac" ]]; then
  echo "❌ Audio codec not AAC (got '$acodec')"; fail=1;
fi
[[ "$fail" -eq 0 ]] && echo "✅ Looks good for App Store Connect" || echo "⚠️ Issues detected"
