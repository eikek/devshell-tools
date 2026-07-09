{
  buildNpmPackage,
  nodejs,
  coreutils,
  fetchFromGitHub,
  npm-lockfile-fix,
  lib,
}:
buildNpmPackage {
  name = "swagger-ui";

  buildInputs = [nodejs];

  src = fetchFromGitHub {
    owner = "swagger-api";
    repo = "swagger-ui";
    rev = "v5.32.8";
    sha256 = "sha256-KB0WplieDk3RM+2dbi7CDDgXScFduKWdmCkBXk+dCQU=";
  };

  npmDepsHash = "sha256-yd4N6pJhPpZpX2aUoxCW4G2wIQUB82LJjQ7sTBt2NTI=";
  npmFlags = [ "--legacy-peer-deps" ];
  # Had to recreate the package-lock.json as there is some bug
  # npm install --package-lock-only --legacy-peer-deps
  postPatch = ''
    cp ${./swagger-ui-package-lock.json} package-lock.json
  '';

  #https://gist.github.com/r-k-b/2485f977b476aa3f76a47329ce7f9ad4
  CYPRESS_INSTALL_BINARY = "0";
  CYPRESS_RUN_BINARY = "${coreutils}/bin/true";

  npmBuildScript = "build:standalone";
}
