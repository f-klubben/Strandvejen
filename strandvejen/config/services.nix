{ pkgs, config, ... }: let

    maintenance = pkgs.callPackage ../../maintenance { address = "${config.strandvejen.address}:${builtins.toString config.strandvejen.port}"; };
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


    systemd.timers.rebuild = {
        enable = true;
        wantedBy = ["default.target"];
        timerConfig = {
            Persistent = true;
            OnCalendar = config.strandvejen.rebuild_time;
            Unit = "rebuild.service";
        };
    };

    systemd.services.rebuild = {
        enable = true;
        serviceConfig.ExecStart = "${pkgs.writeScriptBin "rebuild" ''
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
        ''}/bin/rebuild";
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
