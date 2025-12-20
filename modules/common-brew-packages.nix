# Common Homebrew packages used across multiple hosts
{
brews = [
    "ccat" # Colorized cat - not easily found in nixpkgs
    "doggo" # DNS lookup tool (different from nixpkgs sharing is name)
    "silicon" # Code screenshot generator (the one in nixpkgs is a different thing)
  ];
  ];

  # Add more common packages here as needed
  casks = [
  ];
  taps = ["steveyegge/beads"];
}
