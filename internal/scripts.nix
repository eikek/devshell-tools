{writeShellScriptBin}: {
  cnt-recreate = writeShellScriptBin "cnt-recreate" ''
    cnt=''${DEV_CONTAINER:-dst-test}
    sudo nixos-container destroy $cnt
    sudo nixos-container create $cnt --flake .#test
    sudo nixos-container start dst-test
  '';

  cnt-login = writeShellScriptBin "cnt-login" ''
    cnt=''${DEV_CONTAINER:-dst-test}
    sudo nixos-container root-login $cnt
  '';
}
