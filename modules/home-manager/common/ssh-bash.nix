{ pkgs, ... }:

let
  sshBashPackage = pkgs.writeShellApplication {
    name = "ssh-bash";
    runtimeInputs = [ pkgs.openssh ];
    text = builtins.readFile ../../../scripts/ssh-bash.sh;
  };
in
{
  home.packages = [ sshBashPackage ];
}
