{
    description = "Stregmaskinen nix flake";
    inputs = {
        nixpkgs.url = "nixpkgs/nixos-24.11";
    };
    outputs = { self, nixpkgs, home-manager }: rec {
        nixosConfigurations."x86_64-linux".default = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
                ./system
            ];
        };
        packages."x86_64-linux".default = self.nixosConfigurations."x86_64-linux".default.config.system.build.vm;
    };
}
