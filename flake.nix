{
    description = "F-klubben strandvejen nix flake";
    inputs = {
        nixpkgs.url = "nixpkgs/nixos-24.11";
        nixos-hardware = {
            url = "github:NixOS/nixos-hardware/master";
        };
    };
    outputs = { self, nixpkgs, nixos-hardware }: {
        nixosConfigurations = {
            strandvejen-rpi4 = nixpkgs.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    ./strandvejen
                    ./systems/raspberry-pi-4
                    nixos-hardware.nixosModules.raspberry-pi-4
                ];
            };
            strandvejen = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    ./strandvejen
                    ./systems/strandvejen
                ];
            };
        };
        devShells."x86_64-linux".default = let
            pkgs = import nixpkgs { system = "x86_64-linux"; };
        in  pkgs.mkShellNoCC {
            packages = [
                (pkgs.python312.withPackages (py: with py; [
                    pyqt6
                ]))
                pkgs.figlet
            ];
        };
        packages."x86_64-linux" = let
            pkgs = import nixpkgs { system = "x86_64-linux"; };
        in  {
            default = self.nixosConfigurations.strandvejen.config.system.build.vmWithBootLoader;
            maintenance = import ./maintenance { inherit pkgs; };
            test-image = let 
                wallpaperEditor = pkgs.callPackage ./strandvejen/wallpaperEditor {};
                image = "${pkgs.fetchFromGitHub {
                    owner = "f-klubben";
                    repo = "logo";
                    rev = "master";
                    sha256 = "sha256-ep6/vzk7dj5InsVmaU/x2W1Lsxd4jvvwsyJzLgQJDEE=";
                }}/logo-white-circle-background.png";

            in wallpaperEditor image "Strandvejen for dummies" [
                "you are dumb"
                ":)"
                "<3"
            ];
            plymouth-theme = pkgs.callPackage ./strandvejen/plymouthTheme { mkDerivation = pkgs.stdenv.mkDerivation; };
        };
    };
}
