{
  description = "Huram ARM64 Grml guest image tooling";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs { inherit system; };
      source = ./.;
      manifest = pkgs.writeText "grml-minimal-arm64-packages" ''
        systemd
        systemd-sysv
        ca-certificates
        iproute2
        iputils-ping
        linux-image-arm64
      '';
      measureImage = pkgs.writeShellApplication {
        name = "grml-arm64-measure-image";
        runtimeInputs = [ pkgs.bash pkgs.coreutils pkgs.findutils pkgs.xorriso pkgs.squashfsTools ];
        text = ''
          exec ${pkgs.bash}/bin/bash ${source}/measure-image.sh "$@"
        '';
      };
      bootQemu = pkgs.writeShellApplication {
        name = "grml-arm64-boot-qemu";
        runtimeInputs = [ pkgs.bash pkgs.coreutils pkgs.findutils pkgs.qemu ];
        text = ''
          exec ${pkgs.bash}/bin/bash ${source}/boot-qemu.sh "$@"
        '';
      };
      verify = pkgs.writeShellApplication {
        name = "grml-arm64-verify";
        runtimeInputs = [ pkgs.coreutils pkgs.gnugrep ];
        text = ''
          for pkg in systemd systemd-sysv linux-image-arm64; do
            grep -qx "$pkg" ${manifest}
          done
          echo "PASS: minimal ARM64 package manifest; boot not qualified"
        '';
      };
      buildImage = pkgs.writeShellApplication {
        name = "grml-arm64-build-image";
        runtimeInputs = [ pkgs.bash pkgs.coreutils pkgs.git pkgs.util-linux
          pkgs.shadow pkgs.mmdebstrap pkgs.squashfsTools pkgs.xorriso ];
        text = ''
          exec ${pkgs.bash}/bin/bash ${source}/build-image.sh "$@"
        '';
      };
      inspectImage = pkgs.writeShellApplication {
        name = "grml-arm64-inspect-image";
        runtimeInputs = [ pkgs.bash pkgs.coreutils pkgs.findutils pkgs.xorriso ];
        text = ''
          exec ${pkgs.bash}/bin/bash ${source}/qualify-image.sh "$@"
        '';
      };
    in {
      packages.${system} = {
        inherit manifest verify buildImage inspectImage bootQemu measureImage;
        default = verify;
      };
      apps.${system} = {
        qualify = { type = "app"; program = "${verify}/bin/grml-arm64-verify"; };
        build-image = { type = "app"; program = "${buildImage}/bin/grml-arm64-build-image"; };
        inspect-image = { type = "app"; program = "${inspectImage}/bin/grml-arm64-inspect-image"; };
        boot-qemu = { type = "app"; program = "${bootQemu}/bin/grml-arm64-boot-qemu"; };
        measure-image = { type = "app"; program = "${measureImage}/bin/grml-arm64-measure-image"; };
      };
      checks.${system}.manifest = verify;
    };
}
