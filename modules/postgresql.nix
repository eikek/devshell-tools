{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.dev-postgres;
in {
  options = {
    services.dev-postgres = with lib; {
      enable = mkEnableOption "Dev PostgreSQL";
      users = mkOption {
        type = types.listOf types.str;
        default = ["dev"];
        description = ''
          The users to create. They will have all privileges and the
          password is set to the user name.
        '';
      };
      databases = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of databases to create. Owner is first user in `users`.";
      };
      port = mkOption {
        type = types.int;
        default = 5432;
        description = "The port to bind to.";
      };
    };
  };

  config = lib.mkIf config.services.dev-postgres.enable {
    networking.firewall.allowedTCPPorts = [config.services.postgresql.port];

    services.postgresql = let
      pginit =
        pkgs.writeText "pginit.sql"
        (builtins.concatStringsSep "\n" ((map (user: ''
              CREATE USER dev WITH PASSWORD '${user}' LOGIN CREATEDB;
              GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${user};
              GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${user};
            '')
            cfg.users)
          ++ (map (db: ''
              CREATE DATABASE ${db} OWNER ${builtins.head cfg.users};
            '')
            cfg.databases)));
    in {
      enable = true;
      package = pkgs.postgresql;
      enableTCPIP = true;
      initialScript = pginit;
      port = cfg.port;
      settings = {
        listen_addresses = "*";
      };
      authentication = ''
        host  all  all 0.0.0.0/0 trust
      '';
    };
  };
}
