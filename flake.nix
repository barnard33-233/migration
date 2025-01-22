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
      pkgs-gcc5cross = import nixpkgs-gcc5cross {system = "x86_64-linux"; };
      crossPkgs = pkgs.pkgsCross.aarch64-multiplatform;
      crossPkgs-gcc5cross = pkgs-gcc5cross.pkgsCross.aarch64-multiplatform;
    in
  {
    devShells.x86_64-linux = {
      linux = pkgs.mkShell {
        nativeBuildInputs = with crossPkgs; [
          stdenv.cc
          pkg-config
          pkgs.openssl
          pkgs.binutils
          binutils
        ];
      };

      edk2 = pkgs.mkShell {
        nativeBuildInputs = with crossPkgs; [
          # crossPkgs-gcc5cross.stdenv.cc
          pkg-config
          pkgs.openssl
          pkgs.binutils
          pkgs.libuuid
          binutils
        ];
        shellHook = ''export PATH=/home/mohan/dev/migration/toolchains/aarch64/bin/:$PATH'';
      };
    };
  };
}
