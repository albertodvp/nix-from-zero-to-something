{
  pkgs ? import <nixpkgs> { },
}:
pkgs.stdenv.mkDerivation {
  name = "simple";
  src = ./.;
  installPhase = ''
    mkdir $out
    echo "42" > $out/output
  '';
}
