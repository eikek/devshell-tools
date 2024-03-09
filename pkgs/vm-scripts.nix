{writeShellScriptBin}: let
  key = ../internal/dev-vm-key;
in rec {
  private-get-vm = writeShellScriptBin "vm-get-vm-name" ''
    vm=$DEV_VM
    if [ -z "$DEV_VM" ]; then
        vm="dev-vm"
        echo 1>&2 "No vm name given via env var DEV_VM. Using '$vm'."
    fi
    echo $vm
  '';

  vm-build = writeShellScriptBin "vm-build" ''
    name=$(${private-get-vm}/bin/vm-get-vm-name)
    nix build ".#nixosConfigurations.$name.config.system.build.vm"
  '';

  vm-run = writeShellScriptBin "vm-run" ''
    name=$(${private-get-vm}/bin/vm-get-vm-name)
    nix run ".#nixosConfigurations.$name.config.system.build.vm"
  '';

  vm-ssh = writeShellScriptBin "vm-ssh" ''
    port=''${VM_SSH_PORT:-10022}
    if [ -z "$VM_SSH_PORT" ]; then
        echo "Env var VM_SSH_PORT not defined, using default port 10022."
    fi
    ssh -i ${key} -p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost "$@"
  '';

  vm-logs = writeShellScriptBin "vm-logs" ''
    if [ -z "$1" ]; then
       echo "Please specify a service (dev-solr, postgresql etc)"
       exit 1
    fi
    ${vm-ssh}/bin/vm-ssh journalctl -efu $1.service
  '';

  vm-solr-create-core = writeShellScriptBin "vm-solr-create-core" ''
    core_name=''${1:-default-core}
    if [ -z "$1" ]; then
        echo "No core name specified, using '$core_name'."
    fi
    ${vm-ssh}/bin/vm-ssh "su solr -c \"solr create -c $core_name\""
    ${vm-ssh}/bin/vm-ssh "find /var/solr/data/$core_name/conf -type f -exec chmod 644 {} \;"
  '';

  vm-solr-delete-core = writeShellScriptBin "vm-solr-delete-core" ''
    core_name=''${1:-default-core}
    if [ -z "$1" ]; then
        echo "No core name specified, using '$core_name'."
    fi
    ${vm-ssh}/bin/vm-ssh "su solr -c \"solr delete -c $core_name\""
  '';

  vm-solr-recreate-core = writeShellScriptBin "vm-solr-recreate-core" ''
    ${vm-solr-delete-core}/bin/vm-solr-delete-core "$1"
    ${vm-solr-create-core}/bin/vm-solr-create-core "$1"
  '';
}
