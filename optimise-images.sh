#!/usr/bin/env bash
# Generate AVIF + WebP variants next to every PNG/JPG in a folder,
# and convert every GIF to MP4 + WebM.
#
# Usage:
#   ./optimise-images.sh senseon-brand
#   ./optimise-images.sh senseon-brand senseon-integrations intl-sos
#   ./optimise-images.sh images/senseon-brand   # if you've moved things under images/
#
# Prerequisites (macOS):
#   brew install libavif webp ffmpeg
#
# Safe to re-run. Existing outputs are skipped.

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <folder> [folder ...]" >&2
    exit 1
fi

for tool in avifenc cwebp ffmpeg; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Missing $tool. Run: brew install libavif webp ffmpeg" >&2
        exit 1
    fi
done

AVIF_QUALITY_MIN=30
AVIF_QUALITY_MAX=40
AVIF_SPEED=4
WEBP_QUALITY=78

for folder in "$@"; do
    if [[ ! -d "$folder" ]]; then
        echo "Skipping $folder (not a directory)" >&2
        continue
    fi
    echo ""
    echo "== $folder =="

    shopt -s nullglob
    for src in "$folder"/*.png "$folder"/*.jpg "$folder"/*.jpeg; do
        base="${src%.*}"
        if [[ ! -f "$base.avif" ]]; then
            echo "  avif  $(basename "$src")"
            avifenc --min $AVIF_QUALITY_MIN --max $AVIF_QUALITY_MAX --speed $AVIF_SPEED "$src" "$base.avif" >/dev/null || echo "    (avif failed, skipping)"
        fi
        if [[ ! -f "$base.webp" ]]; then
            echo "  webp  $(basename "$src")"
            cwebp -q $WEBP_QUALITY "$src" -o "$base.webp" >/dev/null 2>&1 || echo "    (webp failed, skipping)"
        fi
    done

    for src in "$folder"/*.gif; do
        base="${src%.*}"
        if [[ ! -f "$base.mp4" ]]; then
            echo "  mp4   $(basename "$src")"
            ffmpeg -y -loglevel error -i "$src" \
                -c:v libx264 -pix_fmt yuv420p -movflags +faststart \
                -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
                "$base.mp4"
        fi
        if [[ ! -f "$base.webm" ]]; then
            echo "  webm  $(basename "$src")"
            ffmpeg -y -loglevel error -i "$src" \
                -c:v libvpx-vp9 -pix_fmt yuva420p -b:v 0 -crf 34 \
                "$base.webm" || echo "    (webm failed, keeping mp4 only)"
        fi
    done
    shopt -u nullglob
done

echo ""
echo "Done. Compare sizes:"
for folder in "$@"; do
    [[ -d "$folder" ]] || continue
    echo "  $folder:"
    du -sh "$folder"/*.png "$folder"/*.jpg "$folder"/*.jpeg "$folder"/*.gif 2>/dev/null | awk '{s+=$1; print}' >/dev/null
    orig=$(du -ch "$folder"/*.png "$folder"/*.jpg "$folder"/*.jpeg "$folder"/*.gif 2>/dev/null | tail -1 | cut -f1)
    opt=$(du -ch "$folder"/*.avif "$folder"/*.webp "$folder"/*.mp4 "$folder"/*.webm 2>/dev/null | tail -1 | cut -f1)
    echo "    originals: ${orig:-0}   optimised: ${opt:-0}"
done
