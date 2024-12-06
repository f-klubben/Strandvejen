{pkgs, lib, ...}:

{
    users.users.treo = {
        isNormalUser = true;
        hashedPassword = "$y$j9T$xsEPa6je/.7ZCV6rBWqXe/$kfmSa/ZylJQ9Hcax5/yZRRjEQws13Fxduqpz7WElqFC";

    };
    users.groups.treo = {};

    services.xserver.enable = true;
    services.xserver.displayManager = {
        lightdm.enable = true;
        autoLogin = {
            enable = true;
            user = "treo";
        };
    };
    
    programs.firefox.enable = true;
    services.xserver.windowManager.i3 = {
        enable = true;
        configFile = pkgs.writeText "config" ''
            exec ${pkgs.firefox}/bin/firefox --kiosk https://stregsystem.fklub.dk
        '';
    };
    system.stateVersion = "24.11";
}