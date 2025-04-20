{ pkgs, config, ... }: let

    
    utils = pkgs.callPackage ../../utils {};
    firefoxPrefix = "${pkgs.firefox}/bin/firefox --kiosk --private-window";
    stregsystemFirefox = ''${firefoxPrefix} "${config.strandvejen.address}:${builtins.toString config.strandvejen.port}/${builtins.toString config.strandvejen.room_id}"'';
    stregsystemFallback = utils.mkPrivilegedScript stregsystemFirefox;
    sourceBg = "${pkgs.fetchFromGitHub {
        owner = "f-klubben";
        repo = "logo";
        rev = "master";
        sha256 = "sha256-ep6/vzk7dj5InsVmaU/x2W1Lsxd4jvvwsyJzLgQJDEE=";
    }}/logo-white-circle-background.png";
    wallpaperEditor = import ./wallpaperEditor { inherit pkgs; };

in {
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

            exec ${pkgs.feh}/bin/feh --bg-scale ${wallpaperEditor sourceBg "Strandvejen for dummies" [
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


}
