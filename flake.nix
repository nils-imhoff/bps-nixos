{
  description = "Manage the NixOS systems of the BPS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";
  inputs.sops-nix.url = "github:Mic92/sops-nix";

  outputs = { self, nixpkgs, nixos-hardware, sops-nix }: {

    nixosModules = builtins.listToAttrs (map (x: {
      name = x;
      value = import (./modules + "/${x}");
    })
    (builtins.attrNames (builtins.readDir ./modules)));

    nixosConfigurations = {
      bps-nextcloud = let system = "x86_64-linux"; in nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ pkgs, ... }: {
            nix.registry.nixpkgs.flake = nixpkgs;
          })
          ./hosts/bps-nextcloud/configuration.nix
          ./hosts/bps-nextcloud/nextcloud.nix
          sops-nix.nixosModules.sops
        ];
      };
    };
  };
}
