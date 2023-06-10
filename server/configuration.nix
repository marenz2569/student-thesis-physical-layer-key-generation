{ secrets, config, pkgs, ... }:

{
  system.stateVersion = "22.05";

  sops.defaultSopsFile = "${secrets}/controller-physec/secrets.yaml";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.configurationLimit = 2;
  boot.cleanTmpDir = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "controller-physec";
}
