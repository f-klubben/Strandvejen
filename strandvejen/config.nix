{config, pkgs, ...}: let
    maintenance = pkgs.callPackage ../maintenance {};
    utils = pkgs.callPackage ../utils {};

    firefoxPrefix = "${pkgs.firefox}/bin/firefox --kiosk --private-window";

    stregsystemFirefox = "${firefoxPrefix} ${config.strandvejen.protocol}://${config.strandvejen.hostname}:${builtins.toString config.strandvejen.port}";

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
        maintenance
        neovim
	    git
	    gcc
        alacritty
        htop
        sqlite
        git
        nix
        figlet
        nixos-rebuild
    ];
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    programs.firefox = {
        enable = true;
        policies = {
            WebsiteFilter = {
                Block = ["<all_urls>"];
                Exceptions = [
                    "${config.strandvejen.protocol}://${config.strandvejen.hostname}/*"
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

            for_window [title="TREO UTIL"] floating enable

            exec --no-startup-id xset s off -dpms

            exec ${pkgs.feh}/bin/feh --bg-scale ${wallpaperEditor bg "Strandvejen for dummies" [
                "Keybinds:"
                "Alt+Shift+s: reload stregsystemet"
                "Alt+Shift+t: maintenance-mode"
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
        serviceConfig.ExecStart = "${maintenance}/bin/maintenance /etc/nixos/maintenance.json";
        wantedBy = ["default.target"];
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
        serviceConfig.ExecStart = "${pkgs.bash}/bin/bash ${../maintenance/rebuild.sh}";
    };

    # this failed to work on the live system, comment in again once its confirmed to work
    # maybe test on rpi or something
    #boot.plymouth = {
    #    enable = true;
    #    themePackages = [
    #        (pkgs.callPackage ./plymouthTheme {})
    #    ];
    #    theme = "nixos-bgrt";
    #};
    nix.gc = {
        automatic = true;
        dates = "Sun 04:00:00";
        persistent = true;
        options = "--delete-older-than 30d";
    };
}
