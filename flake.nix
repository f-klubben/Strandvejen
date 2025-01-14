{
    description = "F-klubben kiosk nix flake";
    inputs = {
        nixpkgs.url = "nixpkgs/nixos-24.11";
        nixos-hardware = {
            url = "github:NixOS/nixos-hardware/master";
        };
        stregsystemet = {
            url = "github:f-klubben/stregsystemet";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };
    outputs = { self, nixpkgs, nixos-hardware, stregsystemet }: {
        nixosConfigurations = {
            kiosk = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    ./kiosk/module.nix
                    {
                        virtualisation.vmVariant = {
                            systemd.services.stregsystemet = {
                                enable = true;
                                serviceConfig = {
                                    ExecStart = "${stregsystemet.packages."x86_64-linux".default}/bin/stregsystemet testserver ${stregsystemet.packages."x86_64-linux".default}/share/stregsystemet/stregsystem/fixtures/testdata.json";
                                };
                                wantedBy = ["default.target"];
                            };
                            # override the kiosk url
                            kiosk = {
                                hostname = "localhost";
                                port = 8000;
                                protocol = "http";

                            };
                        };
                    }
                    ./kiosk
                    ./systems/generic-x86_64
                ];
            };
            kiosk-rpi4 = nixpkgs.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    ./kiosk
                    ./systems/raspberry-pi-4
                    nixos-hardware.nixosModules.raspberry-pi-4
                ];
            };
        };
        devShells."x86_64-linux" = let
            pkgs = import nixpkgs { system = "x86_64-linux"; };
        in  pkgs.mkShellNoCC {
            packages = [
                    pkgs.figlet
            ];
        };
        packages."x86_64-linux" = {
            default = self.nixosConfigurations.kiosk.config.system.build.vm;
            treoutil = import ./treoutil {
                pkgs = import nixpkgs { system = "x86_64-linux"; };
            };
        };
    };
}
