{lib, ...}:

{
    options.strandvejen = {
        address = lib.mkOption {
            type = lib.types.str;
            default = "https://stregsystem.fklub.dk";
        };
        room_id = lib.mkOption {
            type = lib.types.int;
            default = 1;
        };
        should_restart = lib.mkOption {
            type = lib.types.bool;
            default = false;
        };
        extra_packages = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
        };
        local_build = lib.mkOption {
            type = lib.types.bool;
            default = false;
        };
        rebuild_time = lib.mkOption {
            type = lib.types.str;
            default = "Sat 04:00";
        };
        garbage_collection_time = lib.mkOption {
            type = lib.types.str;
            default = "Sun 04:00";
        };
    };
}
