#!/usr/bin/env bash
set -euo pipefail
out="${1:?Usage: qualify-image.sh BUILD_OUTPUT_DIRECTORY}"
iso_dir="$out/image/grml_isos"
test -d "$iso_dir" || { echo 'No Grml ISO output' >&2; exit 2; }
mapfile -t isos < <(find "$iso_dir" -maxdepth 1 -type f -name '*.iso' | sort)
test "${#isos[@]}" -eq 1 || { echo 'Expected exactly one ISO' >&2; exit 2; }
case "$(uname -m)" in
  aarch64) qemu=qemu-system-aarch64 ;;
  x86_64) qemu=qemu-system-x86_64 ;;
  *) echo 'Unsupported native architecture' >&2; exit 2 ;;
esac
command -v xorriso >/dev/null || { echo 'xorriso required' >&2; exit 2; }
command -v "$qemu" >/dev/null || { echo "$qemu required" >&2; exit 2; }
xorriso -indev "${isos[0]}" -report_el_torito plain
sha256sum "${isos[0]}"
echo 'GRUMBLE_INSPECT_RESULT=passed'
echo 'GRUMBLE_BOOT_RESULT=not-qualified'
