{ config,lib, pkgs, ... }:

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
      version = 2;
      forceInstall = true;
      device = "/dev/sda";
    };
  };

  networking = {
    hostName = "bps-nextcloud";
    useDHCP = false;

    interfaces = {
      eth0.useDHCP = true;
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [];
    };
  };

  nix = {
    package = pkgs.nixVersions.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    gc = {
      automatic = true;
      dates = "monthly";
      options = "--delete-older-than 30d";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
    passwordAuthentication = false;
  };

  # this comes with SSH jail by default
  services.fail2ban.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICedqgmNa9A1H1af6TR628y0Rarc9UF8e9VjLc3xNlfTi"
  ];


  system.stateVersion = "24.05";
}