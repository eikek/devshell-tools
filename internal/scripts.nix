{writeShellScriptBin}: {
  cnt-recreate = writeShellScriptBin "cnt-recreate" ''
    cnt=''${DEV_CONTAINER:-devshcnt}
    sudo nixos-container destroy $cnt
    sudo nixos-container create $cnt --flake .#$cnt
    sudo nixos-container start $cnt
  '';

  cnt-login = writeShellScriptBin "cnt-login" ''
    cnt=''${DEV_CONTAINER:-devshcnt}
    sudo nixos-container root-login $cnt
  '';

  cnt-logs = writeShellScriptBin "cnt-logs" ''
    cnt=''${DEV_CONTAINER:-devshcnt}
    sudo nixos-container run $cnt -- journalctl -efu "$1"
  '';
}
