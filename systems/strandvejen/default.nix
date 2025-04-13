{ pkgs, ...}:

{
    imports = [
        ./hardware-configuration.nix
        ./locale.nix
    ];

    networking.hostName = "strandvejen";

    boot.loader.grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        efiInstallAsRemovable = true;
        splashImage = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray}/share/backgrounds/nixos/nix-wallpaper-nineish-dark-gray.png";
    };
    systemd.targets = {
        sleep.enable = false;
        suspend.enable = false;
        hibernate.enable = false;
        hybrid-sleep.enable = false; 
    };
}
