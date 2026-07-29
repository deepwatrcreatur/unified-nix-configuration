# Common Homebrew packages used across multiple hosts
{
  brews = [
    "ccat" # Colorized cat - not easily found in nixpkgs
    "steveyegge/beads/bd" # beads tool
  ];

  casks = [
    "cmux"
  ];

  taps = [
    "manaflow-ai/cmux"
    "steveyegge/beads"
    "xykong/tap"
  ];
}
