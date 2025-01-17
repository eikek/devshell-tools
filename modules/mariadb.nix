{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.dev-mariadb;
in {
  options = {
    services.dev-mariadb = with lib; {
      enable = mkEnableOption "Dev MariaDB";

      users = mkOption {
        type = types.listOf types.str;
        default = ["dev"];
        description = ''
          The users to create. They will have all privileges and the
          password is set to the user name.
        '';
      };
    };
  };

  config = lib.mkIf config.services.dev-mariadb.enable {
    networking.firewall.allowedTCPPorts = [config.services.mysql.settings.mysqld.port];
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      initialScript =
        pkgs.writeText "devmysql-init.sql"
        (builtins.concatStringsSep "\n" (map (user: ''
            CREATE USER IF NOT EXISTS '${user}'
              IDENTIFIED BY '${user}';

            CREATE USER IF NOT EXISTS '${user}'@'localhost'
              IDENTIFIED BY '${user}';

            GRANT ALL
              ON *.*
              TO '${user}'@'%'
              WITH GRANT OPTION;
          '')
          cfg.users));
      settings = {
        mysqld = {
          skip_networking = 0;
          skip_bind_address = true;
        };
      };
    };
  };
}
