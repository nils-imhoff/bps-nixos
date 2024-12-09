{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  time.timeZone = "Europe/Berlin";

  boot = {
    supportedFilesystems = [ "btrfs" ];

    loader.grub = {
      enable = true;
      forceInstall = true;
      device = "/dev/sda";
    };
  };

  networking = {
    hostName = "bps-nextcloud";
    useDHCP = true;

    interfaces = {
      eth0.useDHCP = true;
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
      allowedUDPPorts = [];
    };
  };

  nixpkgs.config = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nix.gc = {
    automatic = true;
    dates = "monthly";
    options = "--delete-older-than 30d";
  };

  environment.systemPackages = with pkgs; [
     git
     vim
     sops
     pinentry-curses
     gnupg
   ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    settings.PasswordAuthentication = true;
  };

  services.fail2ban.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICedqgmNa9A1H1af6TR628y0Rarc9UF8e9VjLc3xNlfTi"
  ];

  system.stateVersion = "24.11";
}
