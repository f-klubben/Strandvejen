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
                ''}
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
                ''}
            ''}/bin/rebuild";
        };
    };

    systemd.services.refresh = {
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
                ${pkgs.git}/bin/git pull
                ${pkgs.nix}/bin/nix flake update maintenance
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch
                ''}
                ${pkgs.sudo}/bin/sudo -u treo ${pkgs.writeScriptBin "reload-i3" ''
                    #!${pkgs.bash}/bin/bash
                    export DISPLAY=:0
                    ${pkgs.i3}/bin/i3 reload
                ''}/bin/reload-i3
            ''}/bin/refresh";
        };
    };

    systemd.services.alacritty = {
        enable = true;
        serviceConfig = {
            User = "treo";
            ExecStart = "${pkgs.writeScriptBin "switch_to_terminal" ''
                #!${pkgs.bash}/bin/bash
                export DISPLAY=:0
                ${pkgs.i3}/bin/i3 exec ${processSwitcher.unprivilegedTerminal}
            ''}/bin/switch_to_terminal";
        };
    };

    systemd.services.ensure_maintenance_flake = {
        enable = true;
        serviceConfig.ExecStart = "${pkgs.writeScriptBin "ensure_maintenance_flake" ''
            #!${pkgs.bash}/bin/bash
            if ! [ -f /var/maintenance/flake.nix ]; then
                ${pkgs.bash}/bin/bash ${../../scripts/initialize.sh}
            fi
        ''}/bin/ensure_maintenance_flake";
        wantedBy = ["default.target"];
    };

}
