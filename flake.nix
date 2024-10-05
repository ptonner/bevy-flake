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
      in
      {
        devShells.default = pkgs.mkShell rec {
          nativeBuildInputs = with pkgs; [
            pkg-config
            (rust-bin.stable.latest.default.override { targets = [ "wasm32-unknown-unknown" ]; })
          ];
          buildInputs = with pkgs; [
            trunk
            udev
            alsa-lib
            vulkan-loader
            xorg.libX11
            xorg.libXcursor
            xorg.libXi
            xorg.libXrandr # To use the x11 feature
          ];
          LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
        };
      }
    );
}
