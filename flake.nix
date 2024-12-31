{
    description = "Stregmaskinen nix flake";
    inputs = {
        nixpkgs.url = "nixpkgs/nixos-24.11";
    };
    outputs = { self, nixpkgs }: {
        nixosConfigurations = builtins.mapAttrs (hostname: system: nixpkgs.lib.nixosSystem {
            system = system;
            modules = [
                ./system
                {
                    networking.hostName = hostname;
                }
            ];
        }) {
            stregmaskinen = "x86_64-linux";
            stregmaskinen-rpi4 = "aarch64-linux";
        };
        devShells."x86_64-linux" = let
            pkgs = import nixpkgs { system = "x86_64-linux"; };
        in  pkgs.mkShellNoCC {
            packages = [
                    pkgs.figlet
            ];
        };
        packages."x86_64-linux" = {
            default = self.nixosConfigurations.stregmaskinen.config.system.build.vm;
            treoutil = import ./treoutil {
                pkgs = import nixpkgs { system = "x86_64-linux"; };
            };
        };
    };
}
