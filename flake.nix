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
      composeJsonSchema = "${composeSpec}/schema/compose-spec.json";
      composeSpec = pkgs.fetchFromGitHub {
        owner = "compose-spec";
        repo = "compose-go";
        rev = "v2.6.5";
        hash = "sha256-gQKGELI+SASHGdmNTGstrcqyHokZQ64Mf8oDMBXpLMc=";
      };
      pkgs = import nixpkgs {inherit system;};
    in {
      devShells.default = pkgs.mkShellNoCC {
        buildInputs =
          (with pkgs; [
            jq
            kompose
            kuttl
          ])
          ++ [travel-kit.packages.${system}.default];

        shellHook = ''
          export COMPOSE_JSON_SCHEMA='${composeJsonSchema}';
          export KOMPOSE_VERSION='${pkgs.kompose.version}';
        '';
      };
    });
}
