{ pkgs, ... }: let

    killList = [
        "firefox"
        "qsudo"
        "alacritty"
    ];

in rec {
    mkPrivilegedScript = fallback: target: "${pkgs.writeScriptBin "privileged-script.sh" ''
        #!${pkgs.bash}/bin/bash
        for executable in ${builtins.concatStringsSep " " killList}; do
            ${pkgs.procps}/bin/pkill -15 $executable
        done
        if ${askPassword}; then
            ${target}
        else
            ${fallback}
        fi
    ''}/bin/privileged-script.sh";

    mkScript = target: "${pkgs.writeScriptBin "script.sh" ''
        #!${pkgs.bash}/bin/bash
        for executable in ${builtins.concatStringsSep " " killList}; do
            ${pkgs.procps}/bin/pkill -15 $executable
        done
        ${target}
    ''}/bin/script.sh";

    askPassword = "${pkgs.qsudo}/bin/qsudo sudo -u treo ls";
}
