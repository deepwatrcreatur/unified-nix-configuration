{
  pkgs,
  ...
}:

{
  imports = [
    ../../../../modules/common/utility-packages.nix
  ];

  environment.systemPackages = with pkgs; [
    ansible
  ];
}
