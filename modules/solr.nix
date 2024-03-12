{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.dev-solr;
in {
  ## interface
  options = with lib; {
    services.dev-solr = {
      enable = mkOption {
        default = false;
        description = "Whether to enable solr.";
      };
      bindAddress = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = "The address to bind to";
      };
      port = mkOption {
        type = types.int;
        default = 8983;
        description = "The port solr is listening on.";
      };
      heap = mkOption {
        type = types.int;
        default = 512;
        description = "The heap setting in megabytes";
      };
      home-dir = mkOption {
        type = types.str;
        default = "/var/solr/data";
        description = "Home dir of solr, to store the data";
      };
      cores = mkOption {
        type = types.listOf types.str;
        default = ["test-core"];
        description = "The cores to create initially.";
      };
    };
  };

  ## implementation
  config = lib.mkIf config.services.dev-solr.enable {
    # Create a user for solr
    users.users.solr = {
      isNormalUser = false;
      isSystemUser = true;
      group = "solr";
      useDefaultShell = true;
    };
    users.groups = {solr = {};};

    # to allow playing with the solr cli
    environment.systemPackages = [pkgs.solr];

    environment.etc = {solr = {source = "${pkgs.solr}/server/solr";};};

    networking.firewall = {
      allowedTCPPorts = [cfg.port];
    };

    # Create directories for storage
    systemd.tmpfiles.rules = [
      "d /var/solr 0755 solr solr - -"
      "d /var/solr/data 0755 solr solr - -"
      "d /var/solr/logs 0755 solr solr - -"
    ];

    systemd.services.dev-solr = {
      enable = true;
      description = "Apache Solr";
      wantedBy = ["multi-user.target"];
      path = with pkgs; [solr lsof coreutils procps gawk];
      environment = {
        SOLR_PORT = toString cfg.port;
        SOLR_JETTY_HOST = cfg.bindAddress;
        SOLR_HEAP = "${toString cfg.heap}m";
        SOLR_PID_DIR = "/var/solr";
        SOLR_HOME = "${cfg.home-dir}";
        SOLR_LOGS_DIR = "/var/solr/logs";
      };
      serviceConfig = {
        ExecStart = "${pkgs.solr}/bin/solr start -f -Dsolr.modules=analysis-extras";
        ExecStop = "${pkgs.solr}/bin/solr stop";
        LimitNOFILE = "65000";
        LimitNPROC = "65000";
        User = "solr";
        Group = "solr";
      };
    };

    # create cores
    systemd.services.solr-init = let
      solrPort = toString cfg.port;
      initSolr = ''
        if [ ! -f ${cfg.home-dir}/cores-created ]; then
          while ! echo "" | ${pkgs.inetutils}/bin/telnet localhost ${solrPort}
          do
             echo "Waiting for SOLR become ready..."
             sleep 1.5
          done
          for core in ${lib.concatStringsSep " " cfg.cores}; do
            ${pkgs.su}/bin/su solr -c "${pkgs.solr}/bin/solr create -c \"$core\" -p ${solrPort}"
          done
          for core in ${lib.concatStringsSep " " cfg.cores}; do
            find ${cfg.home-dir}/$core/conf -type f -exec chmod 644 {} \;
          done
          touch ${cfg.home-dir}/cores-created
        fi
      '';
    in {
      script = initSolr;
      after = ["dev-solr.service"];
      wantedBy = ["multi-user.target"];
      requires = ["dev-solr.service"];
      description = "Create cores at solr";
    };
  };
}
