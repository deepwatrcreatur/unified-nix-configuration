# modules/home-manager/common/dmux.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.dmux;

  # Derivation for the dmux package
  dmux-pkg = pkgs.rustPlatform.buildRustPackage rec {
    pname = "dmux";
    version = "0.6.2"; # From Cargo.toml

    src = pkgs.fetchFromGitHub {
      owner = "zdcthomas";
      repo = "dmux";
      rev = "584aa85Merge pull request #19 from zdcthomas/window-name";
      sha256 = "1cdb7jlav9g5w70mglvxjx1sm9pmgklm19jlp9a7h78mwkhhmxxb";
    };

    cargoHash = "sha256-088m5j6npp11cnwrjlax26svyvixjwikwzbkz84wsc1xfrdcn8vr";

    meta = {
      description = "A fast and easy tmux workspace opener";
      homepage = "https://github.com/zdcthomas/dmux";
      license = licenses.mit;
    };
  };

in
{
  options.programs.dmux = {
    enable = mkEnableOption "dmux - a multi-agent workflow tool";
  };

  config = mkIf cfg.enable {
    home.packages = [ dmux-pkg ];
  };
}
