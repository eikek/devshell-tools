{
  config,
  lib,
  pkgs,
  ...
}: let
  indexhtml = url:
    pkgs.writeText "index.html" ''
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="description" content="SwaggerUI" />
        <title>SwaggerUI</title>
        <link rel="stylesheet" href="/swagger-ui.css" />
      </head>
      <body>
          <div id="swagger-ui"></div>
          <script src="/swagger-ui-bundle.js" crossorigin></script>
          <script src="/swagger-ui-standalone-preset.js" crossorigin></script>
          <script>
           window.onload = () => {
               window.ui = SwaggerUIBundle({
                   url: '${url}',
                   dom_id: '#swagger-ui',
                   presets: [
                       SwaggerUIBundle.presets.apis,
                       SwaggerUIStandalonePreset
                   ]
               });
           };
          </script>
      </body>
      </html>
    '';

  webroot = url:
    pkgs.runCommand "openapi-docs" {} ''
      mkdir $out
      ln -snf ${pkgs.swagger-ui}/lib/node_modules/swagger-ui/dist/* $out/
      ln -snf ${indexhtml url} $out/index.html
    '';
  cfg = config.services.openapi-docs;
in {
  options = with lib; {
    services.openapi-docs = {
      enable = mkEnableOption "openapi-docs";

      port = mkOption {
        type = types.int;
        default = 8081;
        description = "The port to listen on";
      };

      openapi-spec = mkOption {
        type = types.str;
        default = "http://localhost/spec.json";
        description = "The url to a JSON (or yaml) openapi specification";
      };
    };
  };

  config = lib.mkIf config.services.openapi-docs.enable {
    networking.firewall = {
      allowedTCPPorts = [cfg.port];
    };

    services.nginx = {
      enable = true;
      virtualHosts.openapidocs = {
        listen = [
          {
            port = cfg.port;
            addr = "0.0.0.0";
          }
        ];
        locations."/" = {
          root = webroot config.services.openapi-docs.openapi-spec;
        };
      };
    };
  };
}
