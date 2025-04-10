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
            bindsym Mod1+Shift+t exec ${pkgs.writeScriptBin "open-treoutil" ''
                #!${pkgs.bash}/bin/bash
                ${pkgs.procps}/bin/pkill firefox
                if ! ${pkgs.qsudo}/bin/qsudo ${treoutil}/bin/treoutil; then
                    ${pkgs.firefox}/bin/firefox --kiosk --private-window ${config.strandvejen.protocol}://${config.strandvejen.hostname}:${builtins.toString config.strandvejen.port}
                fi
            ''}/bin/open-treoutil
            bindsym Mod1+Shift+Return exec ${pkgs.qsudo}/bin/qsudo -u treo ${pkgs.alacritty}/bin/alacritty
            bindsym Mod1+Shift+s exec ${pkgs.writeScriptBin "open-stregsystem" ''
                if ! [[ $(ps -ef | grep firefox | wc -l) > 1 ]]; then
                    ${pkgs.qsudo}/bin/qsudo -u treo ${pkgs.firefox}/bin/firefox --kiosk --private-window ${config.strandvejen.protocol}://${config.strandvejen.hostname}:${builtins.toString config.strandvejen.port}
                fi
            ''}/bin/open-stregsystem

            for_window [title="TREO UTIL"] floating enable

            bar {}

            exec ${pkgs.feh}/bin/feh --bg-scale ${wallpaperEditor bg "Strandvejen for dummies" [
                "Keybinds:"
                "Alt+Shift+t: treoutil"
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
            OnCalendar = "Sat 04:00:00";
            Unit = "update.service";
        };
    };

    systemd.services.update = {
        enable = true;
        serviceConfig.ExecStart = "${pkgs.bash}/bin/bash ${../treoutil/update.sh}";
    };

    boot.plymouth = {
        enable = true;
        themePackages = [
            (pkgs.callPackage ./plymouthTheme {})
        ];
        theme = "nixos-bgrt";
    };
    nix.gc = {
        automatic = true;
        dates = "Sun 04:00:00";
        persistent = true;
        options = "--delete-older-than 30d";
    };
}
