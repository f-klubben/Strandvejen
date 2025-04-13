{
    imports = [
        ./hardware-configuration.nix
    ];

    networking.hostName = "strandvejen-rpi4";

    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;
    hardware = {
        raspberry-pi."4" = {
            apply-overlays-dtmerge.enable = true;
            fkms-3d.enable = true;
        };
    };
}
