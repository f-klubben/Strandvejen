{ pkgs, address, ... }: let
    utils = pkgs.callPackage ../../../utils {};
in rec {
   stregsystemFirefox = ''${firefoxPrefix} "${address}"'';
   stregsystemFallback = utils.mkPrivilegedScript stregsystemFirefox;
   firefoxPrefix = "${pkgs.firefox}/bin/firefox --kiosk --private-window";
   maintenance = stregsystemFallback "${firefoxPrefix} http://localhost:8080";
   terminal = stregsystemFallback "${pkgs.alacritty}/bin/alacritty";
   unprivilegedTerminal = utils.mkScript "${pkgs.alacritty}/bin/alacritty";
   stregsystem = utils.mkScript "${stregsystemFirefox}";
}
