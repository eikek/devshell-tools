{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  jre,
}:
# https://discourse.nixos.org/t/solr-has-been-removed-what-are-my-options/33504/3
stdenv.mkDerivation rec {
  pname = "solr";
  version = "10.0.0";

  src = fetchurl {
    url = "mirror://apache/solr/${pname}/${version}/${pname}-${version}.tgz";
    sha256 = "sha256-B8GAlw9g0Td2vhPMtgxwfQQeXhqLkU0ZfRNYrCX4BLU=";
  };

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p $out
    cp -r * $out/
    rm -rf $out/bin/init.d
    rm $out/bin/install_solr_service.sh
    rm $out/bin/solr.in.sh
    rm $out/bin/*.cmd

    wrapProgram $out/bin/solr --set JAVA_HOME "${jre}"
  '';

  meta = with lib; {
    homepage = "https://solr.apache.org";
    description = "Open source enterprise search platform from the Apache Lucene project";
    license = licenses.asl20;
    latforms = platforms.all;
    maintainers = with maintainers; [];
  };
}
