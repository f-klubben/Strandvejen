{pkgs, ...}: let 
    source = pkgs.stdenv.mkDerivation {
        name = "treoutil";
        src = ./.;
        installPhase = ''
            mkdir -p $out/share
            cp $src/* $out/share
        '';
    };
    py = pkgs.python3.withPackages (ps: with ps; [ pyqt6 pkgs.figlet ]);
in pkgs.writeScriptBin "maintenance" ''
    #!/usr/bin/env bash
    ${py.interpreter} ${source}/share/maintenance.py "${pkgs.figlet}/bin/figlet"
''
