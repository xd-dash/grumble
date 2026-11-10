#!/usr/bin/env bash
set -euo pipefail
out=${1:?Usage: measure-image.sh BUILD_OUTPUT_DIR}
iso_dir="$out/image/grml_isos"
test -d "$iso_dir" || { echo "No ISO directory" >&2; exit 2; }
mapfile -t isos < <(find "$iso_dir" -maxdepth 1 -type f -name '*.iso' | sort)
test "${#isos[@]}" -eq 1 || { echo "Expected exactly one ISO" >&2; exit 2; }
iso=${isos[0]}
size=$(stat -c '%s' "$iso")
digest=$(sha256sum "$iso" | cut -d' ' -f1)
printf 'ISO bytes: %s\nISO SHA256: %s\n' "$size" "$digest"
if command -v unsquashfs >/dev/null; then
  mapfile -t images < <(xorriso -indev "$iso" -find / -type f -name '*.squashfs' -print 2>/dev/null | grep -E '\.squashfs$' || true)
  printf 'SquashFS files detected: %s\n' "${#images[@]}"
fi
echo "Package count and boot latency require runtime evidence; not inferred from ISO bytes."
