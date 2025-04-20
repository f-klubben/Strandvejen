{ fetchFromGitHub, python312, nixos-bgrt-plymouth, writeText, ... }: let 
    sourceImage = fetchFromGitHub {
        owner = "f-klubben";
        repo = "stregsystemet";
        rev = "next";
        sha256 = "sha256-DY/2lCaBVEmB+SUYrVtLll1m9/SOaaZ3cdX8Q/HvrfQ=";
    };
    env = python312.withPackages (py: with py; [
        pillow
    ]);
in nixos-bgrt-plymouth.overrideAttrs {
    name = "F-Klubbens Plymouth Theme";
    version = "latest";
    installPhase = ''
        runHook preInstall

        mkdir -p $out/share/plymouth/themes/nixos-bgrt
        cp -r $src/*.plymouth $out/share/plymouth/themes/nixos-bgrt/
        cp -r ${sourceImage}/stregsystem/static/stregsystem/cursor/frame0.png ./logo.png
        ${env.interpreter} ${./generate.py}
        mkdir -p $out/share/plymouth/themes/nixos-bgrt/images
        cp images/* $out/share/plymouth/themes/nixos-bgrt/images/
        substituteInPlace $out/share/plymouth/themes/nixos-bgrt/*.plymouth --replace '@IMAGES@' "$out/share/plymouth/themes/nixos-bgrt/images"
        runHook postInstall
    '';
}
