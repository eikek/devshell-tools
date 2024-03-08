{
  description = "Example devshell tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell-tools.url = "github:eikek/devshell-tools";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devshell-tools,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      commonPkgs = [pkgs.jq]; # pick dev tools from nixpkgs
    in {
      devShells = {
        dev-cnt = pkgs.mkShellNoCC {
          buildInputs =
            (builtins.attrValues devshell-tools.legacyPackages.${system}.cnt-scripts)
            ++ commonPkgs;

          DEV_CONTAINER = "dev-cnt";
        };
        dev-vm = pkgs.mkShellNoCC {
          buildInputs =
            (builtins.attrValues devshell-tools.legacyPackages.${system}.vm-scripts)
            ++ commonPkgs;

          DEV_VM = "dev-vm";
          VM_SSH_PORT = "10022";
        };
      };
    })
    // {
      nixosConfigurations = {
        dev-cnt = devshell-tools.lib.mkContainer {
          system = "x86_64-linux";
          modules = [
            {
              services.dev-postgres.enable = true;
              services.dev-email.enable = true;
              services.dev-minio.enable = true;
            }
          ];
        };
        dev-vm = devshell-tools.lib.mkVm {
          system = "x86_64-linux";
          modules = [
            {
              services.dev-postgres.enable = true;
              services.dev-email.enable = true;
              services.dev-minio.enable = true;
              port-forward.ssh = 10022;
              port-forward.dev-postgres = 6534;
              port-forward.dev-smtp = 10025;
              port-forward.dev-imap = 10143;
              port-forward.dev-webmail = 8080;
              port-forward.dev-minio-api = 9000;
              port-forward.dev-minio-console = 9001;
              networking.hostName = "dev-vm";

              #virtualisation.memorySize = 4096;
            }
          ];
        };
      };
    };
}
