{ config, lib, pkgs, ... }:

{
  # Ollama service configuration
  services.ollama = {
    enable = true;
    host = "0.0.0.0";  # Bind to all interfaces
    port = 11434;
    acceleration = "cuda";  # Enable CUDA acceleration
    environmentVariables = {
      OLLAMA_HOST = "0.0.0.0";
      HOME = "/models/ollama";
    };
  };

  # Override systemd service for custom paths
  systemd.services.ollama = {
    environment = {
      HOME = lib.mkForce "/models/ollama";
      OLLAMA_MODELS = lib.mkForce "/models/ollama/models";
    };
    serviceConfig = {
      ReadWritePaths = lib.mkForce [ 
        "/models/ollama" 
        "/models/ollama/models" 
        "/models/ollama/models/blobs" 
      ];
      WorkingDirectory = lib.mkForce "/models/ollama";
      StateDirectory = lib.mkForce "";
    };   
  };

  # Force binary packages and avoid building from source
  nixpkgs.config = {
    allowUnfree = true;
    # Prefer binary substitutes over building
    preferLocalBuild = false;
    allowBuildFromSource = false;
  };

  # Add ollama to system packages - will use available binary version
  # Note: You may need to override the services.ollama.package directly
  # to use a specific older version from nixpkgs history
  environment.systemPackages = with pkgs; [
    ollama
  ];
}