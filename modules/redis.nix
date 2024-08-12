{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.dev-redis;
in {
  options = with lib; {
    services.dev-redis = {
      enable = mkEnableOption "Dev Redis";
      instances = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            port = mkOption {
              type = types.port;
              default = 6379;
              description = "The port for the redis server";
            };
          };
        });
        default = {};
        example = {myredis = {port = 6379;};};
        description = "A set of redis server names to binding ports";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = lib.attrsets.mapAttrsToList (name: mod: mod.port) cfg.instances;
    };

    services.redis.servers =
      lib.mapAttrs (name: mod: {
        enable = true;
        port = mod.port;
        bind = "0.0.0.0";
        openFirewall = true;
        settings = {
          "protected-mode" = "no";
        };
      })
      cfg.instances;
  };
}
