{
  description = "Utilities for devshells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      formatter = pkgs.alejandra;
      packages = {
        solr = pkgs.callPackage (import ./pkgs/solr.nix) {};
      };
    })
    // {
      nixosModules = {
        dev-solr = import ./modules/solr.nix;
        dev-email = import ./modules/email.nix;
        dev-postgres = import ./modules/postgresql.nix;
        dev-mariadb = import ./modules/mariadb.nix;
      };

      overlays = {
        default = final: prev: self.${prev.system}.packages;
      };
    };
}
