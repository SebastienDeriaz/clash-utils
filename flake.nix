# clash-utils flake
# Sébastien Deriaz
# 05.01.2023

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
      };
    in
    {
      inherit pkgs;

      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          (haskellPackages.ghcWithPackages (ps: with ps; [
            clash-ghc
            ghc-typelits-extra
            ghc-typelits-knownnat
            ghc-typelits-natnormalise
          ]))
        ];
      };
    });
}