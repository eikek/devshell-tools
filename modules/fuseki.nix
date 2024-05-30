{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.dev-fuseki;
  fusekiConfig = pkgs.writeText "fuseki-default-config" ''
    # Licensed under the terms of http://www.apache.org/licenses/LICENSE-2.0
    ## Fuseki Server configuration file.

    @prefix :        <#> .
    @prefix fuseki:  <http://jena.apache.org/fuseki#> .
    @prefix rdf:     <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
    @prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
    @prefix ja:      <http://jena.hpl.hp.com/2005/11/Assembler#> .

    [] rdf:type fuseki:Server ;
       # Example::
       # Server-wide query timeout.
       #
       # Timeout - server-wide default: milliseconds.
       # Format 1: "1000" -- 1 second timeout
       # Format 2: "10000,60000" -- 10s timeout to first result,
       #                            then 60s timeout for the rest of query.
       #
       # See javadoc for ARQ.queryTimeout for details.
       # This can also be set on a per dataset basis in the dataset assembler.
       #
       # ja:context [ ja:cxtName "arq:queryTimeout" ;  ja:cxtValue "30000" ] ;

       # Add any custom classes you want to load.
       # Must have a "public static void init()" method.
       # ja:loadClass "your.code.Class" ;

       # End triples.
       .
  '';
  makeFusekiConfg = pkgs.writeScript "copy-fuseki-config.sh" ''
    if [ ! -f "$FUSEKI_BASE/config.ttl" ] ; then
      cp ${fusekiConfig} "$FUSEKI_BASE/config.ttl"
      chmod 644 "$FUSEKI_BASE/config.ttl"
      chown fuseki "$FUSEKI_BASE/config.ttl"
    fi
  '';
in {
  ## interface
  options = with lib; {
    services.dev-fuseki = {
      enable = mkOption {
        default = false;
        description = "Whether to enable jena fuseki.";
      };
      port = mkOption {
        type = types.int;
        default = 3030;
        description = "The port fuseki is listening on.";
      };
      heap = mkOption {
        type = types.int;
        default = 512;
        description = "The heap setting in megabytes";
      };
      home-dir = mkOption {
        type = types.str;
        default = "/var/fuseki";
        description = "Home dir of fuseki, to store the data";
      };
      datasets = mkOption {
        type = types.listOf types.str;
        default = ["testds"];
        description = "The datasets to create initially.";
      };
    };
  };

  ## implementation
  config = lib.mkIf config.services.dev-fuseki.enable {
    # Create a user for fuseki
    users.users.fuseki = {
      isNormalUser = false;
      isSystemUser = true;
      group = "fuseki";
      useDefaultShell = true;
    };
    users.groups = {fuseki = {};};

    # to allow playing with the fuseki cli
    environment.systemPackages = [pkgs.apache-jena-fuseki];

    networking.firewall = {
      allowedTCPPorts = [cfg.port];
    };

    # Create directories for storage
    systemd.tmpfiles.rules = [
      "d ${cfg.home-dir} 0755 fuseki fuseki - -"
    ];

    systemd.services.dev-fuseki = {
      enable = true;
      description = "Apache Fuseki";
      wantedBy = ["multi-user.target"];
      path = with pkgs; [apache-jena-fuseki lsof coreutils procps gawk];
      environment = {
        FUSEKI_HOME = pkgs.apache-jena-fuseki;
        FUSEKI_BASE = "${cfg.home-dir}";
        JVM_ARGS = "-Xmx${toString cfg.heap}m"; # undocumented, but seems to work
        JAVA_TOOL_OPTIONS = "-Xmx${toString cfg.heap}m";
      };
      serviceConfig = {
        ExecStart = "${pkgs.apache-jena-fuseki}/bin/fuseki-server --update --port ${toString cfg.port} --conf=$FUSEKI_BASE/config.ttl";
        ExecStartPre = "${pkgs.bash}/bin/bash ${makeFusekiConfg}";
        User = "fuseki";
        Group = "fuseki";
      };
    };

    # create initial datasets
    systemd.services.fuseki-init = let
      fusekiPort = toString cfg.port;
      initFuseki = ''
        if [ ! -f ${cfg.home-dir}/datasets-created ]; then
          while ! echo "" | ${pkgs.inetutils}/bin/telnet localhost ${fusekiPort}
          do
             echo "Waiting for FUSEKI become ready..."
             sleep 1.5
          done
          for ds in ${lib.concatStringsSep " " cfg.datasets}; do
            ${pkgs.curl}/bin/curl -v --data-urlencode "dbName=''${ds}" --data-urlencode "dbType=tdb2" 'http://localhost:${fusekiPort}/$/datasets'
          done
          touch ${cfg.home-dir}/cores-created
        fi
      '';
    in {
      script = initFuseki;
      after = ["dev-fuseki.service"];
      wantedBy = ["multi-user.target"];
      requires = ["dev-fuseki.service"];
      description = "Create cores at fuseki";
    };
  };
}
