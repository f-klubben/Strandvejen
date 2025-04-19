#!/usr/bin/env bash

rm -rf /var/maintenance

mkdir -p /var/maintenance

cat << EOF > /var/maintenance/settings.json
{
    "strandvejen": {
        "address":"https://stregsystem.fklub.dk",
        "room_id":10,
        "extra_packages":[],
        "should_restart":false,
        "local_build":false,
        "rebuild_time":"Sat 04:00",
        "garbage_collection_time":"Sun 04:00"
    }
}
EOF

cat << EOF > /var/maintenance/flake.nix
{
    outputs = inputs: {
        nixosModules.settings = { pkgs, ... }: pkgs.lib.strings.fromJSON (builtins.readFile ./settings.json );
    };
}
EOF

