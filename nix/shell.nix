{ inputs, ... }:
{
  imports = [ inputs.git-hooks-nix.flakeModule ];
  perSystem =
    { pkgs, config, ... }:
    {
      pre-commit = {
        settings = {
          hooks = {
            nixfmt-rfc-style.enable = true;
            deadnix.enable = true;
            statix.enable = true;
            shellcheck.enable = true;
            typos.enable = true;
            markdownlint = {
              settings.configuration = {
                MD013 = {
                  line_length = 100;
                };
              };
              enable = true;
            };
          };
        };
      };
      devShells.default = pkgs.mkShell {
        buildInputs = config.pre-commit.settings.enabledPackages;
        shellHook = config.pre-commit.installationScript;
      };
      formatter = pkgs.nixfmt-rfc-style;
    };
}
