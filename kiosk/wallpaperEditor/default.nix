{pkgs, ...}: path: title: instructions: let
    # this file is capable of taking an image, a heading, and some instructions, and and the heading and instructions to the image.
    # This is basically to take the readme and make it accessible to the common fember
    env = pkgs.python311.withPackages (py: with py; [
        pillow
    ]);
    instructionsFile = pkgs.writeText "instructions.txt" (builtins.concatStringsSep "\n" instructions);

in pkgs.stdenv.mkDerivation {
    name = "edited-image";
    version = "latest";
    src = ./.;
    buildPhase = ''
        echo "${env.interpreter} editor.py ${path} ${title} ${instructionsFile} image.jpg"
        ${env.interpreter} editor.py "${path}" "${title}" "${instructionsFile}" image.jpg
    '';
    installPhase = ''
        cp image.jpg $out
    '';
}
