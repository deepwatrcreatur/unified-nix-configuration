# Common Homebrew packages used across multiple hosts
{
  brews = [
    "bd" # Steve Yegge's beads project - bd command (requires steveyegge/beads tap)
    "ccat" # Colorized cat - not easily found in nixpkgs
    "gcc" # GCC compiler for Homebrew packages that need it
    "doggo" # DNS lookup tool (different from nixpkgs sharing the name)
    "silicon" # Code screenshot generator (the one in nixpkgs is a different thing)
  ];

  # Add more common packages here as needed
  casks = [
  ];
  taps = ["steveyegge/beads"];
}
