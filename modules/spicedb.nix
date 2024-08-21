{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.dev-spicedb;
  systemdEnv = {
    SPICEDB_DATASTORE_ENGINE = "postgres";
    SPICEDB_DATASTORE_CONN_URI = "postgres://dev:dev@localhost:5432/spicedb";
    SPICEDB_GRPC_PRESHARED_KEY = cfg.preshared-key;
    SPICEDB_HTTP_ENABLED = "false";
    SPICEDB_GRPC_ADDR = ":${toString cfg.port}";
  };
in {
  ## interface
  options = with lib; {
    services.dev-spicedb = {
      enable = mkOption {
        default = false;
        description = "Whether to enable spicedb.";
      };
      preshared-key = mkOption {
        type = types.str;
        default = "dev";
        description = "The preshared key";
      };
      port = mkOption {
        type = types.int;
        default = 50051;
        description = "The port spicedb is listening on.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Create a user for spicedb
    users.users.spicedb = {
      isNormalUser = false;
      isSystemUser = true;
      group = "spicedb";
      useDefaultShell = true;
    };
    users.groups = {spicedb = {};};

    # to allow playing with the spicedb cli
    environment.systemPackages = [pkgs.spicedb pkgs.spicedb-zed];

    services.dev-postgres = {
      enable = true;
      databases = ["spicedb"];
    };

    networking.firewall = {
      allowedTCPPorts = [cfg.port];
    };

    systemd.services.dev-spicedb = {
      environment = systemdEnv;
      description = "Spicedb Server";
      wantedBy = ["multi-user.target"];
      after = ["postgresql.service" "dev-spicedb-migrate.service"];
      serviceConfig = {
        ExecStart = "${pkgs.spicedb}/bin/spicedb serve";
        User = "spicedb";
        Group = "spicedb";
      };
    };
    systemd.services.dev-spicedb-migrate = {
      environment = systemdEnv;
      description = "Run spicedb migrations";
      wantedBy = ["multi-user.target"];
      after = ["postgresql.service"];
      requires = ["postgresql.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.spicedb}/bin/spicedb migrate head";
        RemainsAfterExit = "yes";
      };
    };
  };
}
