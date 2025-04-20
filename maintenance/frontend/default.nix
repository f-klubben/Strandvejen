{ pkgs, address, ... }:

pkgs.stdenv.mkDerivation {
    name = "maintenance-frontend";
    src = ./.;
    installPhase = ''
        ${pkgs.gnused}/bin/sed "s|NIX_PLEASE_CHANGE_ME|${address}|g" index.html > $out
    '';
}
