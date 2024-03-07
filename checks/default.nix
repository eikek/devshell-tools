{...}: {
  imports = [
    ./vm-config.nix
  ];

  services.dev-solr.enable = true;
  services.dev-email.enable = true;
  services.dev-postgres.enable = true;
  services.dev-mariadb.enable = true;
  services.openapi-docs.enable = true;
}
