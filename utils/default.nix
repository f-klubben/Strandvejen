{ pkgs, lib, ... }: let

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
        ${askPassword}
        status=$?
        if [ $status -eq 0 ]; then
            ${target}
        elif [ $status -eq 1 ]; then
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

    getJsonFieldRuntime = jqQuery: ''$(cat $MAINTENANCE_FILE | jq -r "${jqQuery}")'';
}
