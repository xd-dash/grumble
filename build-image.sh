#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
out="${1:-"$PWD/grumble-out"}"
rev=6d729f059769e4d5be18f47bceb9d9f9d0bd5111
case "$(uname -m)" in
  aarch64) class=GRML_MINIMAL_ARM64 ;;
  x86_64) class=GRML_MINIMAL_AMD64 ;;
  *) echo 'Unsupported build architecture' >&2; exit 2 ;;
esac
bash "$root/preflight.sh"
mkdir -p "$out"
out="$(realpath "$out")"
work="$out/grml-live-src"
if [[ ! -d "$work/.git" ]]; then
  git clone https://github.com/grml/grml-live.git "$work"
fi
git -C "$work" fetch --depth=1 origin "$rev"
git -C "$work" checkout --detach "$rev"
test "$(git -C "$work" rev-parse HEAD)" = "$rev"
config="$out/config"
rm -rf "$config"
cp -a "$work/config" "$config"
cp "$root/config/package_config/$class" "$config/package_config/$class"
"$work/grml-live" image-create \
  -F -s trixie -c "$class" -D "$config" \
  "$out/image"
find "$out/image/grml_isos" -maxdepth 1 -type f -name '*.iso' -exec sha256sum {} +
printf '%s\n' "$rev" > "$out/grml-live-revision"
echo 'GRUMBLE_IMAGE_RESULT=built; guest boot remains unqualified.'
