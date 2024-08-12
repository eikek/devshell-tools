{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.dev-authentik;
  env = {
    AK_ADMIN_PASS = "dev";
    AUTHENTIK_BOOTSTRAP_PASSWORD = "dev";
    AK_ADMIN_TOKEN = "dev-token";
    AUTHENTIK_BOOTSTRAP_TOKEN = "dev-token";
    PG_PASS = "dev";
    AUTHENTIK_SECRET_KEY = "xtUkqgAqG7CO1JG2XZ3bqWs42uDnztk11HKiRzueMXsDYbZtbH";
    AUTHENTIK_ERROR_REPORTING__ENABLED = "false";
    # SMTP Host Emails are sent to
    AUTHENTIK_EMAIL__HOST = "localhost";
    AUTHENTIK_EMAIL__PORT = "25";
    # Optionally authenticate (don't add quotation marks to you password)
    AUTHENTIK_EMAIL__USERNAME = "authentik";
    AUTHENTIK_EMAIL__PASSWORD = "authentik";
    # Use StartTLS
    AUTHENTIK_EMAIL__USE_TLS = "false";
    # Use SSL
    AUTHENTIK_EMAIL__USE_SSL = "false";
    AUTHENTIK_EMAIL__TIMEOUT = "10";
    # Email address authentik will send from, should have a correct @domain
    AUTHENTIK_EMAIL__FROM = "authentik@localhost";
    AUTHENTIK_DISABLE_UPDATE_CHECK = "true";
    AUTHENTIK_POSTGRESQL__HOST = "localhost";
    AUTHENTIK_POSTGRESQL__USER = "dev";
    AUTHENTIK_POSTGRESQL__NAME = "authentik";
    AUTHENTIK_POSTGRESQL__PASSWORD = "dev";
    AUTHENTIK_LISTEN__HTTP = "${cfg.bindAddress}:${toString cfg.port}";
    AUTHENTIK_REDIS__PORT = toString cfg.redisPort;
  };
in {
  ## interface
  options = with lib; {
    services.dev-authentik = {
      enable = mkOption {
        default = false;
        description = "Whether to enable authentik.";
      };
      bindAddress = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = "The address to bind to";
      };
      port = mkOption {
        type = types.port;
        default = 9010;
        description = "The port authentik is listening on.";
      };
      redisPort = mkOption {
        type = types.port;
        default = 6888;
        description = "The redis port to use.";
      };

      stateDir = mkOption {
        type = types.str;
        default = "/var/lib/dev-authentik";
        description = "The working directory";
      };
    };
  };

  ## implementation
  config = lib.mkIf cfg.enable {
    # Create a user for authentik
    users.users.authentik = {
      isNormalUser = false;
      isSystemUser = true;
      group = "authentik";
      useDefaultShell = true;
    };
    users.groups = {authentik = {};};

    # to allow playing with the authentik cli
    environment.systemPackages = [pkgs.authentik];

    networking.firewall = {
      allowedTCPPorts = [cfg.port];
    };

    services.dev-postgres = {
      enable = true;
      databases = ["authentik"];
    };
    services.dev-redis = {
      enable = true;
      instances = {
        authentik = {
          port = cfg.redisPort;
        };
      };
    };

    system.activationScripts = {
      "dev-authentik-prepare" = ''
        ${pkgs.coreutils}/bin/mkdir -p "${cfg.stateDir}/media"
        ${pkgs.coreutils}/bin/chown -R authentik:authentik "${cfg.stateDir}"
        ln -snf "${cfg.stateDir}/media" /media
      '';
    };

    systemd.services.dev-authentik = {
      enable = true;
      description = "Authentik";
      wantedBy = ["multi-user.target"];
      path = with pkgs; [authentik coreutils];
      environment = env;
      serviceConfig = {
        ExecStart = "${pkgs.authentik}/bin/ak server";
        WorkingDirectory = cfg.stateDir;
        User = "authentik";
        Group = "authentik";
      };
    };

    systemd.services.dev-authentik-worker = {
      enable = true;
      description = "Authentik Worker";
      wantedBy = ["multi-user.target"];
      path = with pkgs; [authentik coreutils];
      environment = env;
      serviceConfig = {
        ExecStart = "${pkgs.authentik}/bin/ak worker";
        WorkingDirectory = cfg.stateDir;
        User = "authentik";
        Group = "authentik";
      };
    };
  };
}
