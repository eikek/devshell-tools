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
      pgweb = mkOption {
        type = types.submodule {
          options = {
            enable = mkEnableOption "pgweb";
            port = mkOption {
              type = types.int;
              default = 5433;
              description = "The http port to listen on";
            };
            database = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "The default database to connect to";
            };
          };
        };
        default = {
          enable = false;
          port = 5433;
          database = null;
        };
        description = "Enable pgweb";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      config.services.postgresql.port
      cfg.pgweb.port
    ];

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

    users.users.pgweb = lib.mkIf cfg.pgweb.enable {
      isNormalUser = false;
      isSystemUser = true;
      group = "pgweb";
      useDefaultShell = true;
    };
    users.groups = lib.mkIf cfg.pgweb.enable {
      pgweb = {};
    };

    systemd.services.pgweb = lib.mkIf cfg.pgweb.enable {
      enable = true;
      description = "pgweb";
      wantedBy = ["multi-user.target"];
      after = ["postgresql.service"];
      requires = ["postgresql.service"];
      environment = {
      };
      serviceConfig = let
        user = builtins.head cfg.users;
        port = builtins.toString cfg.pgweb.port;
        db =
          if cfg.pgweb.enable && (builtins.length cfg.databases) != 1 && builtins.isNull cfg.pgweb.database
          then builtins.throw "Please specify a database for pgweb or at least one for postgresql - or disable pgweb."
          else if cfg.pgweb.database == null
          then builtins.head cfg.databases
          else cfg.pgweb.database;
      in {
        ExecStart = ''
          ${pkgs.pgweb}/bin/pgweb --bind 0.0.0.0 --listen ${port} --host localhost --user "${user}" --pass "${user}" --db "${db}" --ssl disable
        '';
        User = "pgweb";
        Group = "pgweb";
      };
    };
  };
}
