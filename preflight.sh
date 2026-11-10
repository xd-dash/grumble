#!/usr/bin/env bash
set -euo pipefail

fail() { printf 'GRUMBLE_PREFLIGHT_RESULT=failed reason=%s\n' "$*" >&2; exit 2; }
[[ "$(uname -s)" == Linux ]] || fail 'native Linux required'
case "$(uname -m)" in
  aarch64) system=aarch64-linux; arch=arm64 ;;
  x86_64) system=x86_64-linux; arch=amd64 ;;
  *) fail 'unsupported native architecture' ;;
esac
[[ "${GRUMBLE_SYSTEM:-$system}" == "$system" ]] || fail 'flake system differs from runtime architecture'
[[ "$(id -u)" != 0 ]] || fail 'grml-live must run as an unprivileged user'

for binary in git dpkg mmdebstrap unshare newuidmap newgidmap mksquashfs xorriso python3 rsync socat jo mcopy mkfs.vfat; do
  command -v "$binary" >/dev/null || fail "missing build dependency: $binary"
done
[[ -r /etc/subuid && -r /etc/subgid ]] || fail 'subordinate ID configuration is missing'
user="$(id -un)"
grep -qE "^$user:[0-9]+:[0-9]+$" /etc/subuid || fail 'no subordinate UID range'
grep -qE "^$user:[0-9]+:[0-9]+$" /etc/subgid || fail 'no subordinate GID range'
unshare --user --map-auto -- true || fail 'user namespaces or subordinate ID helpers are unavailable'
printf 'GRUMBLE_PREFLIGHT_RESULT=passed system=%s package_arch=%s\n' "$system" "$arch"
printf '%s\n' 'GRUMBLE_IMAGE_RESULT=not-built GRUMBLE_BOOT_RESULT=not-qualified'
