{pkgs, ...}: let
    treoutil = import ../treoutil {
        pkgs = pkgs;
    };
    bg = "${pkgs.fetchFromGitHub {
        owner = "f-klubben";
        repo = "logo";
        rev = "master";
        sha256 = "sha256-ep6/vzk7dj5InsVmaU/x2W1Lsxd4jvvwsyJzLgQJDEE=";
    }}/logo-white-circle-background.png";
in {
    users.users.treo = {
        isNormalUser = true;
        extraGroups = ["wheel"];
        hashedPassword = "$y$j9T$xsEPa6je/.7ZCV6rBWqXe/$kfmSa/ZylJQ9Hcax5/yZRRjEQws13Fxduqpz7WElqFC";

    };
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;

    users.groups.treo = {};

    services.openssh.enable = true;

    hardware = {
        raspberry-pi."4" = {
            apply-overlays-dtmerge.enable = true;
            fkms-3d.enable = true;
        };
    };
    
    services.xserver.enable = true;
    services.xserver.displayManager = {
        lightdm.enable = true;
    };
    services.displayManager = {
        autoLogin = {
            enable = true;
            user = "treo";
        };
	    defaultSession = "none+i3";
    };

    networking.networkmanager.enable = true;

    environment.systemPackages = with pkgs; [
        treoutil
        neovim
	    git
	    gcc
        alacritty
        libraspberrypi
        raspberrypi-eeprom
    ];
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    programs.sway.enable = true;

    programs.firefox.enable = true;
    services.xserver.windowManager.i3 = {
        enable = true;
        configFile = pkgs.writeText "config" ''
            bindsym Mod1+Shift+t exec ${treoutil}/bin/treoutil
            bindsym Mod1+Shift+q kill
            bindsym Mod1+Shift+d exec ${pkgs.dmenu}/bin/dmenu_run
            bindsym Mod1+Shift+Return exec ${pkgs.alacritty}/bin/alacritty
            bindsym Mod1+Shift+s exec ${pkgs.firefox}/bin/firefox --kiosk https://stregsystem.fklub.dk

            for_window [title="TREO UTIL"] floating enable

            bar {}

            exec ${pkgs.feh}/bin/feh --bg-center ${bg}

            exec ${pkgs.firefox}/bin/firefox --kiosk https://stregsystem.fklub.dk
        '';
    };
    system.stateVersion = "24.11";
}
