{ config, pkgs, ... }:

{
  # Install the Perl-based rename package
  home.packages = with pkgs; [
    prename # Perl-based rename command (prename)
  ];

  # Add shell aliases for safer usage
  home.shellAliases = {
    # Default rename runs in dry-run mode for safety
    rename = "rename -n";
    # Explicitly commit changes with rename-apply
    rename-apply = "rename";
  };
}

