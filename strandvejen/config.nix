{config, pkgs, ...}: let
    treoutil = import ../treoutil {
        pkgs = pkgs;
    };
    bg = "${pkgs.fetchFromGitHub {
        owner = "f-klubben";
        repo = "logo";
        rev = "master";
        sha256 = "sha256-ep6/vzk7dj5InsVmaU/x2W1Lsxd4jvvwsyJzLgQJDEE=";
    }}/logo-white-circle-background.png";
    wallpaperEditor = import ./wallpaperEditor { inherit pkgs; };
in {
    users.users.treo = {
        isNormalUser = true;
        extraGroups = ["wheel"];
        hashedPassword = "$y$j9T$xsEPa6je/.7ZCV6rBWqXe/$kfmSa/ZylJQ9Hcax5/yZRRjEQws13Fxduqpz7WElqFC";

    };
        users.groups.treo = {};

    services.openssh.enable = true;

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
        htop
        sqlite
        git
        nix
        nixos-rebuild
    ];
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    programs.firefox = {
        enable = true;
        policies = {
            WebsiteFilter = {
                Block = ["<all_urls>"];
                Exceptions = ["${config.strandvejen.protocol}://${config.strandvejen.hostname}/*"];
            };
        };
    };

    services.xserver.windowManager.i3 = {
        enable = true;
        configFile = pkgs.writeText "config" ''
            bindsym Mod1+Shift+t exec ${pkgs.qsudo}/bin/qsudo ${treoutil}/bin/treoutil
            bindsym Mod1+Shift+q kill
            bindsym Mod1+Shift+d exec ${pkgs.dmenu}/bin/dmenu_run
            bindsym Mod1+Shift+Return exec ${pkgs.alacritty}/bin/alacritty
            bindsym Mod1+Shift+s exec ${pkgs.firefox}/bin/firefox --kiosk --private-window ${config.strandvejen.protocol}://${config.strandvejen.hostname}:${builtins.toString config.strandvejen.port}

            for_window [title="TREO UTIL"] floating enable

            bar {}

            exec ${pkgs.feh}/bin/feh --bg-scale ${wallpaperEditor bg "Strandvejen for dummies" [
                "Keybinds:"
                "Alt+Shift+t: treoutil"
                "Alt+Shift+Return: alacritty"
                "Alt+Shift+d: dmenu_run"
                "Alt+Shift+q: kill"
                "Alt+Shift+s: reload stregsystemet"
                ""
                "Firefox:"
                "Alt+left: Go back"
                "Alt+right: Go forward"
            ]}

            exec ${pkgs.firefox}/bin/firefox --kiosk --private-window ${config.strandvejen.protocol}://${config.strandvejen.hostname}:${builtins.toString config.strandvejen.port}
        '';
    };
    system.stateVersion = "24.11";

    systemd.timers.update = {
        enable = true;
        wantedBy = ["default.target"];
        timerConfig = {
            Persistent = true;
            OnCalendar = "Sun 23:00:00";
            Unit = "update.service";
        };
    };

    systemd.services.update = {
        enable = true;
        serviceConfig = {
            ExecStart = "${pkgs.writeScriptBin "update.sh" ''
                #!${pkgs.bash}/bin/bash
                set -e
                cd /etc
                rm -rf nixos
                ${pkgs.git}/bin/git clone https://github.com/Mast3rwaf1z/Strandvejen -b final nixos
                cd nixos
                ${pkgs.nix}/bin/nix flake update
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake .#${config.networking.hostName}
                reboot
            ''}/bin/update.sh";
        };
    };
}
