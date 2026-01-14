# Common Homebrew packages used across multiple hosts
{
  brews = [
    "ccat" # Colorized cat - not easily found in nixpkgs
    "doggo" # DNS lookup tool (different from nixpkgs doggo)
    "silicon" # Code screenshot generator (different from nixpkgs silicon)
    "steveyegge/beads/bd" # beads tool
    "tailspin" # log highlighter (tspin)
  ];

  casks = [ ];

  taps = [
    "steveyegge/beads"
  ];
}
