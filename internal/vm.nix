{
  modulesPath,
  config,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/qemu-vm.nix")
    ./port-forwards.nix
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  users.users.root = {
    password = "root";
    openssh.authorizedKeys.keyFiles = [./dev-vm-key.pub];
  };
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  virtualisation.graphics = false;

  documentation.enable = false;
}
