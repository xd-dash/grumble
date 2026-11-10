#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
out=${1:-"$PWD/grml-arm64-out"}
rev=6d729f059769e4d5be18f47bceb9d9f9d0bd5111

[[ $(uname -s) == Linux && $(uname -m) == aarch64 ]] || {
  echo "Build requires native ARM64 Linux" >&2; exit 2;
}
[[ $(id -u) != 0 ]] || {
  echo "Run grml-live as an unprivileged user with /etc/subuid and /etc/subgid ranges" >&2; exit 2;
}
for tool in git dpkg mmdebstrap unshare newuidmap newgidmap mksquashfs xorriso python3 rsync socat jo mcopy mkfs.vfat; do
  command -v "$tool" >/dev/null || { echo "Missing build dependency: $tool" >&2; exit 2; }
done
unshare --user --map-auto -- true || {
  echo "User namespaces or subordinate ID mappings are unavailable" >&2; exit 2;
}
mkdir -p "$out"
out=$(realpath "$out")
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
cp "$root/config/package_config/GRML_MINIMAL_ARM64" "$config/package_config/GRML_MINIMAL_ARM64"
"$work/grml-live" image-create \
  -F -s trixie -c GRML_MINIMAL_ARM64 -D "$config" \
  "$out/image"
find "$out/image/grml_isos" -maxdepth 1 -type f -name '*.iso' -exec sha256sum {} +
printf '%s\n' "$rev" > "$out/grml-live-revision"
echo "Grml ARM64 live ISO built; QEMU boot remains unqualified."
