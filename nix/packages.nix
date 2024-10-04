_: {
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        mkPresentation =
          pkgs.runCommandNoCC "mkPresentation"
            {
              buildInputs = [
                pkgs.pandoc
                pkgs.mermaid-filter
              ];
            }
            ''
              mkdir $out
              cp -r ${../pics} $out/pics
              pandoc ${../README.md} -s \
                -t revealjs \
                -o $out/index.html \
                -F mermaid-filter \
                --variable theme="white" \
                --include-in-header ${../mermaid.html} \
                --slide-level 2
            '';
      };
    };
}
