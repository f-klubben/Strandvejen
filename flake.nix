{
    description = "Stregmaskinen nix flake";
    inputs = {
        nixpkgs.url = "nixpkgs/nixos-24.11";
    };
    outputs = { self, nixpkgs }: {
        nixosConfigurations = builtins.mapAttrs (system: _: { default = nixpkgs.lib.nixosSystem {
            system = system;
            modules = [
                ./system
            ];
        }; }) {
            x86_64-linux = {};
            aarch64-linux = {};
        };
        packages."x86_64-linux".default = self.nixosConfigurations."x86_64-linux".default.config.system.build.vm;
    };
}
