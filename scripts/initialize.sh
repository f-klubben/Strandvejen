#!/usr/bin/env bash

rm -rf /var/maintenance

mkdir -p /var/maintenance

cat << EOF > /var/maintenance/settings.json
{
    "strandvejen": {
        "address":"https://stregsystem.fklub.dk",
        "port":443,
        "room_id":10,
        "extra_packages":[],
        "should_restart":false,
        "rebuild_time":"Sat 04:00:00",
        "garbage_collection_time":"Sun 04:00:00"
    }
}
EOF

cat << EOF > /var/maintenance/flake.nix
{
    inputs.nixpkgs.url = "";
    outputs = inputs: {
        nixosModules.settings = system: (import inputs.nixpkgs { inherit system; }).lib.strings.fromJSON (builtins.readFile ./settings.json );
    };
}
EOF
