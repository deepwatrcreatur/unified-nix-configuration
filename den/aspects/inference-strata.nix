# den/aspects/inference-strata.nix
# GPU-accelerated inference aspect with Strata (Qwen3.8-Flash-Next 125B) on Tesla P40 via nix-strata.
_context:
{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Strata Qwen3.8-Flash-Next 125B inference service
  services.strata-inference = {
    enable = true;
    package = pkgs.strata-inference-p40;
    host = "0.0.0.0";
    port = 8080;
    modelsDir = "/var/lib/strata/models";
    openFirewall = true;
  };

  # Ensure overcommit memory allows large LLM model mappings without aborting
  boot.kernel.sysctl."vm.overcommit_memory" = lib.mkDefault 1;
}
