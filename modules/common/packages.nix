{ config, pkgs, lib, inputs, ... }: {

  environment.systemPackages = with pkgs; [
    # Add packages needed on *all* your systems
  ];
}
