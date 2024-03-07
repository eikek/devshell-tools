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
      instance = mkOption {
        type = types.str;
        default = null;
        description = "Redis instance name.";
      };
    };
  };

  config = lib.mkIf config.services.dev-redis.enable {
    networking.firewall = {
      allowedTCPPorts = [6379];
    };

    services.redis.servers.${cfg.instance} = {
      enable = true;
      port = 6379;
      bind = "0.0.0.0";
      openFirewall = true;
      settings = {
        "protected-mode" = "no";
      };
    };
  };
}
