{
  description = "Utilities for devshells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
  }: let
    legacyPackages = pkgs: let
      startsWith = s: (
        name: v: nixpkgs.lib.strings.hasPrefix s name
      );
      filter = s: set: nixpkgs.lib.attrsets.filterAttrs (startsWith s) set;
      vm-scripts = filter "vm-" (import ./pkgs/vm-scripts.nix {
        inherit (pkgs) writeShellScriptBin;
      });
      cnt-scripts = filter "cnt-" (import ./pkgs/cnt-scripts.nix {
        inherit (pkgs) writeShellScriptBin jq;
      });
    in {
      inherit vm-scripts cnt-scripts;
    };

    devshellToolsPkgs = pkgs: let
      scripts = legacyPackages pkgs;
      sbts = pkgs.callPackage (import ./pkgs/sbt.nix) {};
      mills = pkgs.callPackage (import ./pkgs/mill.nix) {};
      postgres-fg = pkgs.callPackage (import ./pkgs/postgres-fg.nix) {};
    in
      rec {
        solr = pkgs.callPackage (import ./pkgs/solr.nix) {};
        swagger-ui = pkgs.callPackage (import ./pkgs/swagger-ui.nix) {};
        openapi-docs = pkgs.callPackage (import ./pkgs/openapi-docs.nix) {
          inherit swagger-ui;
        };
        inherit (sbts) sbt11 sbt17 sbt21;
        inherit (mills) mill17 mill21;
        inherit postgres-fg;
      }
      // scripts.vm-scripts
      // scripts.cnt-scripts;

    pkgsBySystem = system:
      import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      };
  in
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      formatter = pkgs.alejandra;
      packages = devshellToolsPkgs pkgs;

      legacyPackages = legacyPackages pkgs;

      devShells.default = pkgs.mkShellNoCC {
        buildInputs = let
          internalScripts = pkgs.callPackage (import ./internal/scripts.nix) {};
        in [
          internalScripts.cnt-recreate
          internalScripts.cnt-login
          internalScripts.cnt-logs
          (devshellToolsPkgs pkgs).postgres-fg
        ];

        DEV_CONTAINER = "devshcnt";
      };

      checks =
        (devshellToolsPkgs pkgs)
        // (
          if pkgs.stdenv.isLinux
          then {
            services = with import (nixpkgs + "/nixos/lib/testing-python.nix")
            {
              inherit system;
            };
              makeTest {
                name = "devshell-tools";
                nodes = {
                  machine = {...}: {
                    imports =
                      (builtins.attrValues self.nixosModules)
                      ++ [
                        {nixpkgs.pkgs = pkgsBySystem system;}
                        ./checks
                      ];
                  };
                };

                testScript = builtins.readFile ./checks/testScript.py;
              };
          }
          else {}
        );
    })
    // rec {
      nixosModules = {
        dev-solr = import ./modules/solr.nix;
        dev-email = import ./modules/email.nix;
        dev-postgres = import ./modules/postgresql.nix;
        dev-mariadb = import ./modules/mariadb.nix;
        dev-redis = import ./modules/redis.nix;
        dev-minio = import ./modules/minio.nix;
        openapi-docs = import ./modules/openapi-docs.nix;
        dev-fuseki = import ./modules/fuseki.nix;
        dev-keycloak = import ./modules/keycloak.nix;
        dev-authentik = import ./modules/authentik.nix;
        dev-spicedb = import ./modules/spicedb.nix;
      };

      nixosConfigurations = {
        devshcnt = lib.mkContainer {
          system = "x86_64-linux";
          modules = [
            {
              services.dev-postgres = {
                enable = true;
                #                databases = ["mydb"];
              };
              networking.hostName = "devshcnt";
            }
          ];
        };
      };

      overlays = {
        default = final: prev: devshellToolsPkgs final;
      };

      lib = import ./lib {
        inherit inputs;
        inherit (self) nixosModules;
        inherit pkgsBySystem;
      };

      templates.default = {
        path = ./template;
        description = "An example template for devshell-tools";
      };
    };
}
