# hosts/macminim4/homebrew.nix
{ config, pkgs, ... }:

{
  homebrew = {
    # Formulas (CLI tools)
    brews = [
      "aom"
      "atomicparsley"
      "cmake"
      "leptonica"
      "mise"
      "msgpack"
    ];

    # Casks (GUI apps)
    casks = [
      "phantomjs"
    ];
  };
}
