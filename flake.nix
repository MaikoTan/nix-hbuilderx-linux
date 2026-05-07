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
          };
        };

        version = "5.07.2026041006";

        src = pkgs.fetchzip {
          url= "https://download1.dcloud.net.cn/download/HBuilderX.${version}.linux_x64.full.tar.gz";
          sha256 = "sha256-ywmxRJlYxIq/NO/JqBUCbCGnjCatvqxdcT/tH8LB82g=";
        };

        meta = with pkgs.lib; {
          mainProgram = "hbuilderx";
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

            mkdir -p $out/{bin,share}
            cp -r $src $out/share/hbuilderx
            ln -s $out/share/hbuilderx/cli $out/bin/hbuilderx

            wrapProgram $out/bin/hbuilderx \
              --prefix PATH : ${pkgs.lib.makeBinPath runtimeBins} \
              --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeLibs}

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
