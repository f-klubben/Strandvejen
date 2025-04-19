{ config, lib, pkgs, ... }: let

    maintenance = pkgs.callPackage ../maintenance {};
    utils = pkgs.callPackage ../utils {};

    firefoxPrefix = "${pkgs.firefox}/bin/firefox --kiosk --private-window";

    stregsystemFirefox = ''${firefoxPrefix} "${config.strandvejen.address}/${builtins.toString config.strandvejen.room_id}"'';

    stregsystemFallback = utils.mkPrivilegedScript stregsystemFirefox;


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
        maintenance
        neovim
	    git
        alacritty
        htop
        git
        nix
        figlet
        nixos-rebuild
        jq
    ] ++ (map (package: pkgs.${package}) config.strandvejen.extra_packages);

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    programs.firefox = {
        enable = true;
        policies = {
            WebsiteFilter = {
                Block = ["<all_urls>"];
                Exceptions = [
                    "${config.strandvejen.address}/*"
                    "http://localhost/*"
                ];
            };
        };
    };

    services.xserver.windowManager.i3 = {
        enable = true;
        configFile = pkgs.writeText "config" ''
            bindsym Mod1+Shift+t exec ${stregsystemFallback 
                "${firefoxPrefix} http://localhost:8080"
            }

            bindsym Mod1+Shift+Return exec ${stregsystemFallback 
                "${pkgs.alacritty}/bin/alacritty"
            }

            bindsym Mod1+Shift+s exec ${utils.mkScript 
                stregsystemFirefox
            }

            exec --no-startup-id xset s off -dpms

            exec ${pkgs.feh}/bin/feh --bg-scale ${wallpaperEditor bg "Strandvejen for dummies" [
                "Keybinds:"
                "Alt+Shift+s: reload stregsystemet"
                "Alt+Shift+t: maintenance-mode"
                "Alt+Shift+Enter: terminal"
                ""
                "Firefox:"
                "Alt+left: Go back"
                "Alt+right: Go forward"
            ]}

            exec ${stregsystemFirefox}
        '';
    };

    systemd.services.maintenance = {
        enable = true;
        path = with pkgs; [
            git
            nix
            nixos-rebuild
            procps
            alacritty
        ];
        environment = {
            DISPLAY=":0";
        };
        serviceConfig.ExecStart = "${maintenance}/bin/maintenance";
        wantedBy = ["default.target"];
    };

    system.stateVersion = "24.11";

    systemd.timers.update = {
        enable = true;
        wantedBy = ["default.target"];
        timerConfig = {
            Persistent = true;
            OnCalendar = config.strandvejen.rebuild_time;
            Unit = "rebuild.service";
        };
    };

    systemd.services.update = {
        enable = true;
        serviceConfig.ExecStart = "${pkgs.writeScriptBin "update" ''
            #!${pkgs.bash}/bin/bash
            set -e
            ${if config.strandvejen.local_build then ''
                cd /etc/nixos
                ${pkgs.git}/bin/git pull
                ${pkgs.nix}/bin/nix flake update
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch
            '' else ''
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake github:f-klubben/Strandvejen
            ''}
            ${if config.strandvejen.should_restart then "reboot" else ""}
        ''}/bin/update";
    };

    systemd.services.ensure_maintenance_flake = {
        enable = true;
        serviceConfig.ExecStart = "${pkgs.writeScriptBin "ensure_maintenance_flake" ''
            #!${pkgs.bash}/bin/bash
            if ! [ -f /var/maintenance/flake.nix ]; then
                ${pkgs.bash}/bin/bash ${../scripts/initialize.sh}
            fi
        ''}/bin/ensure_maintenance_flake";
        wantedBy = ["default.target"];
    };

    nix.gc = {
        automatic = true;
        dates = config.strandvejen.garbage_collection_time;
        persistent = true;
        options = "--delete-older-than 30d";
    };
}
