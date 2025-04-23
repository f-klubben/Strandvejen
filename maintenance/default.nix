{ pkgs, address, ... }: let 
    frontend = pkgs.callPackage ./frontend { address = address; };
    source = pkgs.stdenv.mkDerivation {
        name = "maintenance";
        src = ./.;
        installPhase = ''
            mkdir -p $out/frontend
            cp $src/api.py $out
            cp ${frontend} $out/frontend/index.html
        '';
    };
    py = pkgs.python3.withPackages (ps: with ps; [ pyqt6 pkgs.figlet ]);
in pkgs.writeScriptBin "maintenance" ''
    #!${pkgs.bash}/bin/bash
    ${py.interpreter} ${source}/api.py $@
''
