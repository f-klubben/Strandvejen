{ config, pkgs, ... }:

{
    users.users.treo = {
        isNormalUser = true;
        extraGroups = ["wheel"];
        hashedPassword = "$y$j9T$xsEPa6je/.7ZCV6rBWqXe/$kfmSa/ZylJQ9Hcax5/yZRRjEQws13Fxduqpz7WElqFC";

    };
    users.groups.treo = {};
    networking.networkmanager.enable = true;

    environment.systemPackages = with pkgs; [
        neovim
	    git
        alacritty
        htop
        git
        nix
        figlet
        nixos-rebuild
        jq
    ] ++ (map (package: pkgs.${package}) config.strandvejen.extra_packages);

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.gc = {
        automatic = true;
        dates = config.strandvejen.garbage_collection_time;
        persistent = true;
        options = "--delete-older-than 30d";
    };

    system.stateVersion = "24.11";
}
