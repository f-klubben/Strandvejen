{pkgs, ...}: let 
    source = pkgs.stdenv.mkDerivation {
        name = "treoutil";
        src = ./.;
        installPhase = ''
            mkdir -p $out/share
            cp -r $src/* $out/share
        '';
    };
    py = pkgs.python3.withPackages (ps: with ps; [ pyqt6 pkgs.figlet ]);
in pkgs.writeScriptBin "maintenance" ''
    #!${pkgs.bash}/bin/bash
    ${py.interpreter} ${source}/share/api.py
''
