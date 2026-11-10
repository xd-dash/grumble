{
  description = "Grumble: reproducible Grml live-image tooling";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-linux" "x86_64-linux" ];
      eachSystem = nixpkgs.lib.genAttrs systems;
    in {
      packages = eachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          arch = if system == "aarch64-linux" then "arm64" else "amd64";
          packageClass = "GRML_MINIMAL_${if system == "aarch64-linux" then "ARM64" else "AMD64"}";
          source = ./.;
          buildTools = with pkgs; [
            bash coreutils git cacert util-linux shadow mmdebstrap dpkg
            squashfsTools xorriso python3 rsync socat jo mtools dosfstools
          ];
          wrap = name: script: tools: pkgs.writeShellApplication {
            inherit name;
            runtimeInputs = tools;
            text = ''
              export GRUMBLE_SYSTEM=${system}
              exec ${pkgs.bash}/bin/bash ${source}/${script} "$@"
            '';
          };
          qualify = wrap "grumble-qualify" "preflight.sh" buildTools;
          build = wrap "grumble-build" "build-image.sh" buildTools;
          inspect = wrap "grumble-inspect" "qualify-image.sh"
            (with pkgs; [ bash coreutils findutils xorriso qemu ]);
          boot = wrap "grumble-boot" "boot-qemu.sh"
            (with pkgs; [ bash coreutils findutils qemu ]);
          measure = wrap "grumble-measure" "measure-image.sh"
            (with pkgs; [ bash coreutils findutils gnugrep xorriso squashfsTools ]);
          static = pkgs.runCommand "grumble-${arch}-static" {
            nativeBuildInputs = with pkgs; [ bash gnugrep ];
          } ''
            for script in preflight.sh build-image.sh qualify-image.sh boot-qemu.sh measure-image.sh; do
              bash -n ${source}/"$script"
            done
            grep -qx linux-image-${arch} ${source}/config/package_config/${packageClass}
            mkdir -p "$out"
            echo 'GRUMBLE_STATIC_RESULT=passed' > "$out/result"
          '';
        in {
          inherit qualify build inspect boot measure static;
          default = qualify;
        });
      apps = eachSystem (system:
        let
          p = self.packages.${system};
          mkApp = pkg: name: { type = "app"; program = "${pkg}/bin/${name}"; };
        in {
          default = mkApp p.qualify "grumble-qualify";
          qualify = mkApp p.qualify "grumble-qualify";
          build = mkApp p.build "grumble-build";
          inspect = mkApp p.inspect "grumble-inspect";
          boot = mkApp p.boot "grumble-boot";
          measure = mkApp p.measure "grumble-measure";
        });
      checks = eachSystem (system: {
        static = self.packages.${system}.static;
      });
    };
}
