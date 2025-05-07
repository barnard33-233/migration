{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-gcc5cross = {
      url = "github:NixOS/nixpkgs/nixos-22.05";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-gcc5cross}:
    let
      pkgs = import nixpkgs {system = "x86_64-linux";};
      crossPkgs = pkgs.pkgsCross.aarch64-multiplatform;
    in
  {
    devShells.x86_64-linux = {
      linux = pkgs.mkShell {
        nativeBuildInputs = with crossPkgs; [
          pkg-config
          pkgs.openssl
          pkgs.binutils
          binutils
        ];
        shellHook=''
          export TOOLCHAINS_PATH=/home/mohan/dev/migration/toolchains/aarch64/bin/
          export PATH=$TOOLCHAINS_PATH:$PATH
        '';
      };

      firmware = pkgs.mkShell {
        nativeBuildInputs = with crossPkgs; [
          pkg-config
          pkgs.openssl
          pkgs.binutils
          pkgs.libuuid
          pkgs.bear
          binutils
        ];
        shellHook = ''
          export TOOLCHAINS_PATH=/home/mohan/dev/migration/toolchains/aarch64/bin/
          export PATH=$TOOLCHAINS_PATH:$PATH
          export CROSS_COMPILE=aarch64-linux-gnu-
        '';
      };

      l2qemu = pkgs.mkShell {

      };
    };
  };
}
