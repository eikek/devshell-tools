{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.dev-keycloak;
in {
  options = with lib; {
    services.dev-keycloak = {
      enable = mkOption {
        default = false;
        description = "Whether to enable jena fuseki.";
      };
      hostname = mkOption {
        type = types.str;
        default = config.networking.hostName;
        description = ''
          The hostname for keycloak. Defaults to `networking.hostName`.
          Might be necessary to set for keycloak to work properly.
        '';
      };
      http-port = mkOption {
        type = types.int;
        default = 8180;
        description = "The web http port";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.dev-postgres = {
      enable = true;
      databases = ["keycloak"];
      create-password-files = lib.mkForce true;
    };

    services.keycloak = {
      enable = true;
      settings = {
        hostname = cfg.hostname;
        hostname-strict = false;
        hostname-strict-https = false;
        http-port = cfg.http-port;
        https-port = 8443;
        http-enabled = true;
        http-host = "0.0.0.0";
      };
      initialAdminPassword = "dev";
      database = {
        type = "postgresql";
        port = config.services.dev-postgres.port;
        host = "localhost";
        name = "keycloak";
        username = builtins.head config.services.dev-postgres.users;
        createLocally = false;
        passwordFile = "/var/lib/pgpass_${config.services.keycloak.database.username}";
      };
    };

    environment.systemPackages = [pkgs.keycloak];

    networking.firewall.allowedTCPPorts = [cfg.http-port 8443];
  };
}
