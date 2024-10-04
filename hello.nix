{
  pkgs ? import <nixpkgs> { },
}:
pkgs.stdenv.mkDerivation {
  name = "hello";
  src = ./src;
  buildInputs = [ pkgs.rustc ];
  buildPhase = ''
    rustc $src/hello.rs -o ./hello
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp ./hello $out/bin
  '';
}
