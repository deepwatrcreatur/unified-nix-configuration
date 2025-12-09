{ lib, ... }:

{
  # Enable Ollama service with CUDA acceleration
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = 11434;
    acceleration = "cuda";
    environmentVariables = {
      OLLAMA_HOST = "0.0.0.0";
      OLLAMA_MODELS = "/models/ollama/models";
    };
  };

  # Custom model storage path
  systemd.services.ollama.environment.HOME = lib.mkForce "/models/ollama";
  systemd.services.ollama.serviceConfig = {
    ReadWritePaths = lib.mkForce [ "/models/ollama" ];
    WorkingDirectory = lib.mkForce "/models/ollama";
    StateDirectory = lib.mkForce "";
  };
}
