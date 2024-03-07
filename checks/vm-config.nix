{
  config,
  pkgs,
  ...
}: {
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };
  console.keyMap = "us";

  users.users.root = {
    password = "root";
  };

  services.xserver = {
    enable = false;
  };

  networking = {
    hostName = "dst-test";
  };

  system.stateVersion = "23.11";

  # This slows down the build of a vm
  documentation.enable = false;
}
