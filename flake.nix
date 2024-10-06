{
  description = "A devShell example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        lib = pkgs.lib;
        inherit (pkgs) rust-bin makeRustPlatform;
        rustPlatform = makeRustPlatform {
          cargo = rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
          rustc = rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
        };
        nativeBuildInputs = with pkgs; [
          pkg-config
          (rust-bin.stable.latest.default.override { targets = [ "wasm32-unknown-unknown" ]; })
          wasm-bindgen-cli
        ];
        buildInputs = with pkgs; [
          udev
          alsa-lib
          vulkan-loader
          xorg.libX11
          xorg.libXcursor
          xorg.libXi
          xorg.libXrandr # To use the x11 feature
          libxkbcommon
        ];
        webBuildInputs = builtins.concatLists [
          (with pkgs; [
            simple-http-server
            wasm-bindgen-cli
            trunk
          ])
          buildInputs
        ];
        version = "0.1";
        pname = "bevy-flake";
      in
      {
        packages.default = rustPlatform.buildRustPackage {
          inherit
            nativeBuildInputs
            buildInputs
            version
            pname
            ;
          src = ./.;
          cargoLock = {
            lockFile = ./Cargo.lock;
          };
          LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
        };
        packages.web = rustPlatform.buildRustPackage {
          inherit nativeBuildInputs version;
          buildInputs = webBuildInputs;
          pname = pname + "-web";
          src = ./.;
          cargoLock = {
            lockFile = ./Cargo.lock;
          };
          buildPhase = ''
            cargo build --release --target=wasm32-unknown-unknown

            echo 'Creating out dir...'
            mkdir -p $out/src;

            echo 'Generating node module...'
            wasm-bindgen \
              --out-name wasm \
              --target web \
              --out-dir $out/src \
              target/wasm32-unknown-unknown/release/bevy-flake.wasm;
          '';
          installPhase = "echo 'Skipping installPhase'";
        };
        devShells.default = pkgs.mkShell rec {
          inherit nativeBuildInputs;
          buildInputs = webBuildInputs;
          LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
        };
      }
    );
}
