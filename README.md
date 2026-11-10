# Grumble

Independent Grml live-image build and qualification tools for native Linux ARM64 and x86-64.

**Status:** source migration completed; neither architecture has a qualified Grml ISO or verified guest boot.

Source provenance is recorded in [provenance.json](provenance.json). The upstream `grml-live` checkout remains pinned to `6d729f059769e4d5be18f47bceb9d9f9d0bd5111`.

## Ownership

- Grumble owns Grml configuration, source pins, build scripts and image qualification.
- `xd-dash/nix.xd` owns native architecture selection, Nix-Alpine bootstrap and runtime orchestration.
- One separate Nix-Alpine writer and volume belong to Grumble. Do **not** mount Agni/CoreOS's writable `/nix` here.
- No Smoke or Huram credential is required for normal builds; Huram was used only to bootstrap this repository.

## Nix application interface

The same flake app names are exposed on `aarch64-linux` and `x86_64-linux`:

```sh
nix flake check
nix run .#qualify
nix run .#build -- /workspaces/grumble-out
nix run .#inspect -- /workspaces/grumble-out
nix run .#measure -- /workspaces/grumble-out
nix run .#boot -- /workspaces/grumble-out /path/to/uefi-code.fd
```

`#qualify` is **preflight only**. It checks Linux architecture, native tools, non-root execution, subordinate ID configuration and functioning user namespaces. It must not be interpreted as ISO or boot qualification. `#build` invokes upstream `grml-live image-create`, `#inspect` checks optical boot metadata, and `#boot` starts a manual QEMU serial session.

Grml automatically includes other classes such as GRMLBASE; this experiment is not yet a minimal installed OS.

## Mac ARM64 Nix-Alpine

From `~/workspace/nix.xd` on the isolated `codex/grumble-isolated-writer` branch:

```sh
make bootstrap PROVIDER=container ARCH=arm64 SCOPE=nix-xd-grumble-arm \
  IMAGE=localhost/nix-xd-grumble:arm64 NIX_XD_STORE_SIZE=40G
make store-isolation-check PROVIDER=container ARCH=arm64 \
  ISOLATION_PRIMARY=nix-xd-arm ISOLATION_SECONDARY=nix-xd-grumble-arm
make sync PROVIDER=container ARCH=arm64 REPO=xd-dash/grumble \
  WORKSPACES="$HOME/workspace" BRANCH=codex/mac-nix-alpine-qualification
make stage PROVIDER=container ARCH=arm64 SCOPE=nix-xd-grumble-arm \
  WORKSPACES="$HOME/workspace" CHECKOUT=grumble
make qualify PROVIDER=container ARCH=arm64 SCOPE=nix-xd-grumble-arm \
  FLAKE=grumble
```

After merging the qualification branch, switch to `BRANCH=main` or select an exact tested commit for reproducible runs.

The native build is not yet proven on Alpine. In particular, the unprivileged `mmdebstrap`/user-namespace prerequisites may fail under Apple container. The preflight must fail closed, not silently upgrade container privileges or alter the existing Nix store.

## Qualification still required

1. Independent writer mount identity and persistence.
2. Native build prerequisites including unprivileged UID/GID mapping.
3. ISO build with logs and SHA256.
4. QEMU UEFI boot and serial evidence for kernel, systemd and login.
5. Network/DHCP verification, image size and boot-time measurement.

No Blacksmith build is authorized by these application scripts.
