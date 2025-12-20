# Common Homebrew packages used across multiple hosts
# Note: beads requires manual install: brew tap steveyegge/beads && brew install beads
{
  brews = [
    "ccat" # Colorized cat - not easily found in nixpkgs
    "doggo" # DNS lookup tool (different from nixpkgs doggo)
    "silicon" # Code screenshot generator (different from nixpkgs silicon)
  ];

  casks = [];
  
  taps = [];
}
