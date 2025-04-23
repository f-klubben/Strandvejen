{ pkgs, config, ... }: let

    maintenance = pkgs.callPackage ../../maintenance { address = "${config.strandvejen.address}:${builtins.toString config.strandvejen.port}"; };
    processSwitcher = pkgs.callPackage ./processSwitcher {
        address = "${config.strandvejen.address}:${builtins.toString config.strandvejen.port}/${builtins.toString config.strandvejen.room_id}";
    };

in {
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


    systemd.timers.update = {
        enable = true;
        wantedBy = ["default.target"];
        timerConfig = {
            Persistent = true;
            OnCalendar = config.strandvejen.rebuild_time;
            Unit = "update.service";
        };
    };

    systemd.services.update = {
        enable = true;
        path = with pkgs; [
            git
        ];
        serviceConfig = {
            StandardError = "journal";
            ExecStart = "${pkgs.writeScriptBin "update" ''
                #!${pkgs.bash}/bin/bash
                set -e
                cd /etc/nixos
                ${pkgs.git}/bin/git pull
                ${pkgs.nix}/bin/nix flake update nixpkgs nixos-hardware
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch
                ${if config.strandvejen.should_restart then "reboot" else ""}
            ''}/bin/update";
        };
    };

    systemd.services.rebuild = {
        enable = true;
        path = with pkgs; [
            git
        ];
        serviceConfig = {
            StandardError = "journal";
            ExecStart = "${pkgs.writeScriptBin "rebuild" ''
                #!${pkgs.bash}/bin/bash
                set -e
                cd /etc/nixos
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch
                ${pkgs.sudo}/bin/sudo -u treo ${pkgs.writeScriptBin "reload-i3" ''
                    #!${pkgs.bash}/bin/bash
                    export DISPLAY=:0
                    ${pkgs.i3}/bin/i3 reload
                ''}/bin/reload-i3
            ''}/bin/rebuild";
        };
    };

    systemd.services.refresh-settings = {
        enable = true;
        path = with pkgs; [
            git
        ];
        serviceConfig = {
            StandardError = "journal";
            ExecStart = "${pkgs.writeScriptBin "refresh" ''
                #!${pkgs.bash}/bin/bash
                set -e
                cd /etc/nixos
                ${pkgs.nix}/bin/nix flake update maintenance
            ''}/bin/refresh";
        };
    };

    systemd.services.pull = {
        enable = true;
        path = with pkgs; [
            git
        ];
        serviceConfig = {
            ExecStart = "${pkgs.writeScriptBin "pull" ''
                #!${pkgs.bash}/bin/bash
                set -e
                cd /etc/nixos
                ${pkgs.git}/bin/git pull
            ''}/bin/pull";
        };
    };

    systemd.services.refresh-inputs = {
        enable = true;
        path = with pkgs; [
            git
        ];
        serviceConfig = {
            StandardError = "journal";
            ExecStart = "${pkgs.writeScriptBin "refresh" ''
                #!${pkgs.bash}/bin/bash
                set -e
                cd /etc/nixos
                ${pkgs.nix}/bin/nix flake update nixos-hardware nixpkgs
            ''}/bin/refresh";
        };
    };

    systemd.services.terminal = {
        enable = true;
        serviceConfig = {
            User = "treo";
            ExecStart = "${pkgs.writeScriptBin "switch-to-terminal" ''
                #!${pkgs.bash}/bin/bash
                export DISPLAY=:0
                ${pkgs.i3}/bin/i3 exec ${processSwitcher.unprivilegedTerminal}
            ''}/bin/switch-to-terminal";
        };
    };

    systemd.services.ensure-nix-env = {
        enable = true;
        serviceConfig.ExecStart = "${pkgs.writeScriptBin "ensure-maintenance-flake" ''
            #!${pkgs.bash}/bin/bash
            if ! [ -f /var/maintenance/flake.nix ]; then
                ${pkgs.bash}/bin/bash ${../../scripts/initialize.sh}
            fi
            if ! [ -f /etc/nixos/flake.nix ]; then
                rm -rf /etc/nixos
                ${pkgs.git}/bin/git clone https://github.com/f-klubben/Strandvejen /etc/nixos
                cd /etc/nixos
                ${pkgs.nix}/bin/nix flake update maintenance
            fi
        ''}/bin/ensure-maintenance-flake";
        wantedBy = ["default.target"];
    };

}
