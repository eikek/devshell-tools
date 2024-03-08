{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.dev-minio;
in {
  options = with lib; {
    services.dev-minio = {
      enable = mkEnableOption "Minio";

      api-port = mkOption {
        type = types.int;
        default = 9000;
        description = "The port to listen on";
      };
      console-port = mkOption {
        type = types.int;
        default = 9001;
        description = "The port for the web console";
      };
      accessKey = mkOption {
        type = types.str;
        default = "minioadmin";
        description = "The access key used to access the server";
      };
      secretKey = mkOption {
        type = types.str;
        default = "minioadmin";
        description = "The secret key used to access the server";
      };
      region = mkOption {
        type = types.str;
        default = "us-east-1";
        description = "The region setting indicating the physical location.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      cfg.api-port
      cfg.console-port
    ];

    services.minio = let
      rootFile = pkgs.writeText "minio-root" ''
        MINIO_ROOT_USER=${cfg.accessKey}
        MINIO_ROOT_PASSWORD=${cfg.secretKey}
      '';
    in {
      enable = true;
      listenAddress = "0.0.0.0:${builtins.toString cfg.api-port}";
      consoleAddress = "0.0.0.0:${builtins.toString cfg.console-port}";
      browser = true;
      rootCredentialsFile = rootFile;
      region = cfg.region;
    };
  };
}
