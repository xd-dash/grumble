# Grml ARM64 QEMU baseline

Huram-owned experimental Grml live ISO for aarch64. No Podman, Wisp, or
CoreOS-replacement claim. The upstream grml-live source is pinned to
`6d729f059769e4d5be18f47bceb9d9f9d0bd5111`.

## Scope

Upstream grml-live **automatically includes GRMLBASE** and the ARM64 class,
in addition to our GRML_MINIMAL_ARM64 class. GRMLBASE contains significant
rescue and firmware packages. This is a boot baseline, **not yet a minimal
installed OS**. Measure first, then reduce deliberately.

## Native build

Use an ARM64 Linux builder with the full grml-live runtime dependencies,
configured user namespaces and subordinate UID/GID mappings. Run as a
non-root user. The builder invokes upstream `grml-live image-create` directly.

```sh
bash experiments/grml-arm64/build-image.sh "$PWD/grml-arm64-out"
bash experiments/grml-arm64/qualify-image.sh "$PWD/grml-arm64-out"
bash experiments/grml-arm64/measure-image.sh "$PWD/grml-arm64-out"
```

Nix is optional and only wraps the native scripts:

```sh
nix run ./experiments/grml-arm64#build-image -- "$PWD/grml-arm64-out"
nix run ./experiments/grml-arm64#inspect-image -- "$PWD/grml-arm64-out"
nix run ./experiments/grml-arm64#measure-image -- "$PWD/grml-arm64-out"
```

## QEMU boot

With an ARM64 UEFI firmware code file (e.g. AAVMF_CODE.fd):

```sh
bash experiments/grml-arm64/boot-qemu.sh "$PWD/grml-arm64-out" /path/to/AAVMF_CODE.fd
```

The QEMU script is a manual smoke entrypoint; it does not assert successful
UEFI boot, systemd readiness, network connectivity or console login.
Those require captured runtime evidence. The live ISO is not a persistent
installed disk. Record firmware identity and serial output when testing.

## Evidence required for qualification

1. Full native grml-live log, exact upstream revision and ISO SHA256.
2. QEMU serial log showing kernel, systemd and login.
3. DHCP address and reachable network from the guest.
4. ISO bytes, boot time, and guest `dpkg-query -W` package count.
5. Repeatable boot and negative failure tests before reducing GRMLBASE.

Blacksmith 2-vCPU ARM64 pseudo-dispatch is static preflight only.
No image build or VM boot has been verified.
