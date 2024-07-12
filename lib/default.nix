{
  inputs,
  nixosModules,
  pkgsBySystem,
}: let
  nixpkgs = inputs.nixpkgs;
in {
  installScript = {
    system,
    script,
  }:
    nixpkgs.legacyPackages.${system}.stdenvNoCC.mkDerivation {
      name = builtins.baseNameOf script;
      src = script;
      unpackPhase = "true";
      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/$name
        chmod 755 $out/bin/$name
      '';
    };

  mkContainer = {
    system,
    modules,
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        (builtins.attrValues nixosModules)
        ++ [
          {
            nixpkgs.pkgs = pkgsBySystem system;
            system.stateVersion = "24.05";
            boot.isContainer = true;
          }
        ]
        ++ modules;
    };

  mkVm = {
    system,
    modules,
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        (builtins.attrValues nixosModules)
        ++ [
          {
            nixpkgs.pkgs = pkgsBySystem system;
            system.stateVersion = "24.05";
          }
          ../internal/vm.nix
        ]
        ++ modules;
    };
}
