{pkgs, ...}: let 
    source = pkgs.stdenv.mkDerivation {
        name = "treoutil";
        src = ./.;
        installPhase = ''
            mkdir -p $out/share
            cp $src/* $out/share
        '';
    };
    py = pkgs.python3.withPackages (ps: with ps; [ pyqt6 ]);
in pkgs.writeScriptBin "treoutil" ''
    #!/usr/bin/env bash
    ${py.interpreter} ${source}/share/treoutil.py "${pkgs.figlet}/bin/figlet"
''
