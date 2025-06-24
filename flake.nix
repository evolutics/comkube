{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    travel-kit.url = "github:evolutics/travel-kit";
  };

  outputs = {
    flake-utils,
    nixpkgs,
    travel-kit,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      devShells.default = pkgs.mkShellNoCC {
        buildInputs =
          (with pkgs; [
            kind
            kompose
            kuttl
          ])
          ++ [travel-kit.packages.${system}.default];

        shellHook = ''
          export KIND_EXPERIMENTAL_PROVIDER=podman;
        '';
      };
    });
}
