{ config, pkgs, lib, inputs, ... }: {

  environment.systemPackages = with pkgs; [
     graphite-cli
     grok-cli
     sops
  ];
}
