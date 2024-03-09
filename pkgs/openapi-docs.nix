{ swagger-ui, python3, stdenvNoCC, writeText }:
stdenvNoCC.mkDerivation {
  name = "openapi-docs-0.0.1";

  unpackPhase = "true";
  buildPhase = "true";
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/openapi-docs
    chmod 755 $out/bin/openapi-docs
  '';

  src = writeText "openapi-docs.py" ''
    #!${python3}/bin/python3

    import tempfile
    import webbrowser
    from http.server import HTTPServer, SimpleHTTPRequestHandler
    import os
    import argparse

    swagger_dir="${swagger-ui}/lib/node_modules/swagger-ui/dist"

    parser = argparse.ArgumentParser("openapi-docs")
    parser.add_argument("url", help="The url to the openapi spec")
    args = parser.parse_args()
    spec_url=args.url

    with tempfile.TemporaryDirectory() as tmpdir:
        print("Created", tmpdir)
        for f in os.listdir(swagger_dir):
            os.symlink(os.path.join(swagger_dir, f), os.path.join(tmpdir, f))

        with open(os.path.join(tmpdir, "index.html"), "w") as f:
            f.write("""
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
                         url: '%s',
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
            """ % spec_url)

        class Handler(SimpleHTTPRequestHandler):
            def __init__(self, *args, **kwargs):
                super().__init__(*args, **kwargs, directory=tmpdir)

        server = HTTPServer(("localhost", 3000), Handler)
        webbrowser.open("http://localhost:3000")
        server.serve_forever()
  '';
}
