{
  config,
  lib,
  ...
}: let
  cfg = config.port-forward;
in {
  options = {
    port-forward = with lib; {
      ssh = mkOption {
        type = types.port;
        default = 10022;
        description = "The target port for ssh on the host";
      };
      dev-postgres = mkOption {
        type = types.port;
        default = 15432;
        description = "The target port for postgres on the host";
      };
      dev-pgweb = mkOption {
        type = types.port;
        default = 15433;
        description = "The target port for pgweb on the host";
      };
      dev-solr = mkOption {
        type = types.port;
        default = 18983;
        description = "The target port for solr on the host";
      };
      dev-smtp = mkOption {
        type = types.port;
        default = 10025;
        description = "The target port for smtp on the host";
      };
      dev-imap = mkOption {
        type = types.port;
        default = 10143;
        description = "The target port for imap on the host";
      };
      dev-webmail = mkOption {
        type = types.port;
        default = 8080;
        description = "The target port for webmail on the host";
      };
      openapi-docs = mkOption {
        type = types.port;
        default = 8081;
        description = "The target port for openapi docs on the host";
      };
      dev-redis = mkOption {
        type = types.port;
        default = 16379;
        description = "The target port for redis on the host";
      };
      dev-mariadb = mkOption {
        type = types.port;
        default = 3330;
        description = "The target port for mariadb on the host";
      };
      dev-minio-api = mkOption {
        type = types.port;
        default = 9000;
        description = "The minio api port";
      };
      dev-minio-console = mkOption {
        type = types.port;
        default = 9001;
        description = "The minio console port";
      };
      dev-fuseki = mkOption {
        type = types.port;
        default = 3030;
        description = "The fuseki server port";
      };
      dev-keycloak = mkOption {
        type = types.port;
        default = 8180;
        description = "The keycloak web port";
      };
      dev-authentik = mkOption {
        type = types.port;
        default = 9010;
        description = "The authentik web port";
      };
      dev-spicedb = mkOption {
        type = types.port;
        default = 50051;
        description = "The spicedb grpc port";
      };
    };
  };

  config = {
    virtualisation.forwardPorts = with lib; [
      (mkIf config.services.dev-postgres.enable {
        from = "host";
        host.port = cfg.dev-postgres;
        guest.port = config.services.postgresql.settings.port;
      })
      (mkIf config.services.dev-postgres.pgweb.enable {
        from = "host";
        host.port = cfg.dev-pgweb;
        guest.port = config.services.dev-postgres.pgweb.port;
      })
      (mkIf config.services.openssh.enable {
        from = "host";
        host.port = cfg.ssh;
        guest.port = 22;
      })
      (mkIf config.services.dev-solr.enable {
        from = "host";
        host.port = cfg.dev-solr;
        guest.port = config.services.dev-solr.port;
      })
      (mkIf config.services.dev-email.enable {
        from = "host";
        host.port = cfg.dev-smtp;
        guest.port = 25;
      })
      (mkIf config.services.dev-email.enable {
        from = "host";
        host.port = cfg.dev-imap;
        guest.port = 143;
      })
      (mkIf config.services.dev-email.enable {
        from = "host";
        host.port = cfg.dev-webmail;
        guest.port = config.services.dev-email.webmail-port;
      })
      (mkIf config.services.openapi-docs.enable {
        from = "host";
        host.port = cfg.openapi-docs;
        guest.port = config.services.openapi-docs.port;
      })
      (mkIf config.services.dev-redis.enable {
        from = "host";
        host.port = cfg.dev-redis;
        guest.port = 6379;
      })
      (mkIf config.services.dev-mariadb.enable {
        from = "host";
        host.port = cfg.dev-mariadb;
        guest.port = config.services.mysql.settings.mysqld.port;
      })
      (mkIf config.services.dev-minio.enable {
        from = "host";
        host.port = cfg.dev-minio-api;
        guest.port = config.services.dev-minio.api-port;
      })
      (mkIf config.services.dev-minio.enable {
        from = "host";
        host.port = cfg.dev-minio-console;
        guest.port = config.services.dev-minio.console-port;
      })
      (mkIf config.services.dev-fuseki.enable {
        from = "host";
        host.port = cfg.dev-fuseki;
        guest.port = config.services.dev-fuseki.port;
      })
      (mkIf config.services.dev-keycloak.enable {
        from = "host";
        host.port = cfg.dev-keycloak;
        guest.port = config.services.dev-keycloak.http-port;
      })
      (mkIf config.services.dev-authentik.enable {
        from = "host";
        host.port = cfg.dev-authentik;
        guest.port = config.services.dev-authentik.port;
      })
      (mkIf config.services.dev-spicedb.enable {
        from = "host";
        host.port = cfg.dev-spicedb;
        guest.port = config.services.dev-spicedb.port;
      })
    ];
  };
}
