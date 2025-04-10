{ pkgs, ...}:

{
    imports = [
        ./hardware-configuration.nix
    ];

    boot.loader.grub = {
        enable = true;
        splashImage = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray}/share/backgrounds/nixos/nix-wallpaper-nineish-dark-gray.png";
    };
}
