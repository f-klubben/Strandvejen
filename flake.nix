{
    description = "F-klubben kiosk nix flake";
    inputs = {
        nixpkgs.url = "nixpkgs/nixos-24.11";
        nixos-hardware = {
            url = "github:NixOS/nixos-hardware/master";
        };
        stregsystemet = {
            # TODO: change to upstream url when merged
            url = "github:Mast3rwaf1z/stregsystemet/nix-updates";
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
                        environment.systemPackages = [stregsystemet.packages."x86_64-linux".default];
                        virtualisation.vmVariant = {
                            # import vm depends
                            imports = [
                                stregsystemet.nixosModules.default
                            ];
                            # override the kiosk url
                            kiosk = {
                                hostname = "localhost";
                                port = 80;
                                protocol = "http";

                            };
                            # custom options from stregsystemet
                            stregsystemet = {
                                enable = true;
                                port = 80;
                                hostnames = ["localhost"];
                                testData.enable = true;
                                debug.debug = false;
                            };
                            virtualisation.resolution = {
                                x = 1280;
                                y = 720;
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
        packages."x86_64-linux" = let
            pkgs = import nixpkgs { system = "x86_64-linux"; };
        in  {
            default = self.nixosConfigurations.kiosk.config.system.build.vm;
            treoutil = import ./treoutil { inherit pkgs; };
            test-image = let 
                wallpaperEditor = import ./kiosk/wallpaperEditor { inherit pkgs; };
                image = "${pkgs.fetchFromGitHub {
                    owner = "f-klubben";
                    repo = "logo";
                    rev = "master";
                    sha256 = "sha256-ep6/vzk7dj5InsVmaU/x2W1Lsxd4jvvwsyJzLgQJDEE=";
                }}/logo-white-circle-background.png";

            in wallpaperEditor image "Kiosk for dummies" [
                "you are dumb"
                ":)"
                "<3"
            ];
        };
    };
}
