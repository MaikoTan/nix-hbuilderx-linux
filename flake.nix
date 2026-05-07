{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              "openssl-1.1.1w"
            ];
          };
        };

        version = "5.07.2026041006";

        src = pkgs.fetchzip {
          url= "https://download1.dcloud.net.cn/download/HBuilderX.${version}.linux_x64.full.tar.gz";
          sha256 = "sha256-ywmxRJlYxIq/NO/JqBUCbCGnjCatvqxdcT/tH8LB82g=";
        };

        meta = with pkgs.lib; {
          mainProgram = "hbuilderx-cli";
          description = "A (self-claimed) superpowered IDE for Vue from DCloud.io";
          license = [
            licenses.unfree # The software is not open source
            licenses.mit # The package script is MIT licensed
          ];
          maintainers = with maintainers; [ maikotan ];
        };

        runtimeLibs = with pkgs; [
          glib
          libGL
          libpng
          harfbuzz
          freetype
          xorg.libXrender
          xorg.libX11
          xorg.libxcb
          fontconfig
          pcre2
          zlib
          openssl_1_1
        ];

        runtimeBins = with pkgs; [
          nodejs_22
          procps
          xz
          cacert
        ];

        package = pkgs.stdenv.mkDerivation {
          name = "HBuilderX-${version}";
          inherit src meta;

          dontBuild = true;

          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = runtimeLibs;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin

            cat > $out/bin/hbuilderx <<EOF
            #!${pkgs.runtimeShell}
            export PATH=${pkgs.lib.makeBinPath runtimeBins}:\$PATH
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath runtimeLibs}:\$LD_LIBRARY_PATH
            exec ${src}/HBuilderX "\$@"
            EOF
            chmod +x $out/bin/hbuilderx

            cat > $out/bin/hbuilderx-cli <<EOF
            #!${pkgs.runtimeShell}
            export PATH=${pkgs.lib.makeBinPath runtimeBins}:\$PATH
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath runtimeLibs}:\$LD_LIBRARY_PATH
            exec ${src}/cli "\$@"
            EOF
            chmod +x $out/bin/hbuilderx-cli

            runHook postInstall
          '';
        };
      in
      {
        packages.default = package;
        packages.hbuilderx = package;
      }
    );
}
