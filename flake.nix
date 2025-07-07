{
  description = "Ayrton's NixOS and Home Manager Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    sddm-sugar-candy-nix = {
      url = "gitlab:Zhaith-Izaliel/sddm-sugar-candy-nix";
    };    
    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };    
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, sddm-sugar-candy-nix, stylix, ... }@inputs: {
    
    nixosConfigurations.nova-nix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        sddm-sugar-candy-nix.nixosModules.default
        ./configuration.nix
        ./hardware-configuration.nix
        home-manager.nixosModules.home-manager
        stylix.nixosModules.stylix        
        {
          home-manager.useGlobalPkgs = true; # Share nixpkgs with the system
          home-manager.useUserPackages = true; # Install user packages to /home/ayrton/.nix-profile
          home-manager.users.ayrton = import ./home-manager/home.nix;
          home-manager.backupFileExtension = "backup";          
          home-manager.extraSpecialArgs = {
            unstable = import nixpkgs-unstable {
              system = "x86_64-linux";
              config.allowUnfree = true;
              config.allowUnfreePredicate = (_: true);
            };
          };
        }
      ];
    };
  };
}