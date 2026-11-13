#!/usr/bin/env bash
set -euo pipefail

out="${1:?Usage: boot-qemu.sh BUILD_OUTPUT_DIR [FIRMWARE_CODE_FD]}"
firmware="${2:-${GRUMBLE_UEFI_CODE:-${AAVMF_CODE:-${OVMF_CODE:-}}}}"
[[ -n "$firmware" && -f "$firmware" ]] || {
  echo 'Supply a matching UEFI firmware code image as argument or GRUMBLE_UEFI_CODE' >&2; exit 2;
}
mapfile -t isos < <(find "$out/image/grml_isos" -maxdepth 1 -type f -name '*.iso' | sort)
[[ ${#isos[@]} -eq 1 ]] || { echo 'Expected exactly one ISO' >&2; exit 2; }
case "$(uname -m)" in
  aarch64)
    exec qemu-system-aarch64 \
      -machine virt,accel=tcg -cpu cortex-a72 -smp 2 -m 2048 \
      -drive "if=pflash,format=raw,readonly=on,file=$firmware" \
      -device virtio-scsi-pci \
      -drive "if=none,id=cdrom,media=cdrom,readonly=on,file=${isos[0]}" \
      -device scsi-cd,drive=cdrom \
      -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
      -nographic -no-reboot
    ;;
  x86_64)
    exec qemu-system-x86_64 \
      -machine q35,accel=tcg -cpu max -smp 2 -m 2048 \
      -drive "if=pflash,format=raw,readonly=on,file=$firmware" \
      -drive "file=${isos[0]},media=cdrom,if=ide,readonly=on" \
      -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
      -nographic -no-reboot
    ;;
  *) echo 'Unsupported native architecture' >&2; exit 2 ;;
esac
