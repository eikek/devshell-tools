{
  writeShellScriptBin,
  jq,
}: rec {
  private-get-cnt = writeShellScriptBin "cnt-get-container-name" ''
    cnt=$DEV_CONTAINER
    if [ -z "$DEV_CONTAINER" ]; then
        if nix flake show --quiet --json 2> /dev/null | ${jq}/bin/jq -e '.nixosConfigurations."dev-cnt"?' > /dev/null; then
            cnt="dev-cnt"
        else
            cnt="container"
        fi
        echo 1>&2 "No container name given via env var DEV_CONTAINER. Using '$cnt'."
    fi
    echo $cnt
  '';

  cnt-recreate = writeShellScriptBin "cnt-recreate" ''
    cnt=$(${private-get-cnt}/bin/cnt-get-container-name)
    sudo nixos-container destroy $cnt
    echo "Creating and starting container $cnt ..."
    sudo nixos-container create $cnt --flake .#$cnt
    sudo nixos-container start $cnt
  '';

  cnt-destroy = writeShellScriptBin "cnt-destroy" ''
    cnt=$(${private-get-cnt}/bin/cnt-get-container-name)
    sudo nixos-container destroy $cnt
  '';

  cnt-start = writeShellScriptBin "cnt-start" ''
    cnt=$(${private-get-cnt}/bin/cnt-get-container-name)
    sudo nixos-container start $cnt
  '';

  cnt-stop = writeShellScriptBin "cnt-stop" ''
    cnt=$(${private-get-cnt}/bin/cnt-get-container-name)
    sudo nixos-container stop $cnt
  '';

  cnt-login = writeShellScriptBin "cnt-login" ''
    cnt=$(${private-get-cnt}/bin/cnt-get-container-name)
    sudo nixos-container root-login $cnt
  '';

  cnt-solr-create-core = writeShellScriptBin "cnt-solr-create-core" ''
    cnt=$(${private-get-cnt}/bin/cnt-get-container-name)
    core_name=''${1:-default-core}
    if [ -z "$1" ]; then
        echo "No core name specified, using '$core_name'."
    fi
    sudo nixos-container run $cnt -- su solr -c "solr create -c $core_name"
    sudo nixos-container run $cnt -- find /var/solr/data/$core_name/conf -type f -exec chmod 644 {} \;
  '';

  cnt-solr-delete-core = writeShellScriptBin "cnt-solr-delete-core" ''
    cnt=$(${private-get-cnt}/bin/cnt-get-container-name)
    core_name=''${1:-default-core}
    if [ -z "$1" ]; then
        echo "No core name specified, using '$core_name'."
    fi
    sudo nixos-container run $cnt -- su solr -c "solr delete -c $core_name"
  '';

  cnt-solr-recreate-core = writeShellScriptBin "cnt-solr-recreate-core" ''
    ${cnt-solr-delete-core}/bin/cnt-solr-delete-core "$1"
    ${cnt-solr-create-core}/bin/cnt-solr-create-core "$1"
  '';

  cnt-logs = writeShellScriptBin "cnt-logs" ''
    if [ -z "$1" ]; then
       echo "Please specify a service (dev-solr, postgresql etc)"
       exit 1
    fi
    cnt=$(${private-get-cnt}/bin/cnt-get-container-name)
    sudo nixos-container run $cnt -- journalctl -efu $1.service
  '';
}
