{ ... }:

{
  users.users.ansible = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];

    # TODO: replace with hashedPassword or authorizedKeys
    password = "secret";
  };

  services.openssh.enable = true;

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
}
