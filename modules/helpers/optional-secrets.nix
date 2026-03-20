# modules/lib/optional-secrets.nix
#
# Helper library for defining agenix secrets that gracefully degrade
# when the encrypted .age file doesn't exist. This enables:
# - Merging branches before creating secrets
# - Running partial configurations on new machines
# - Clean conditional logic without repeated boilerplate
#
# Usage:
#   let
#     optSec = import ../lib/optional-secrets.nix { inherit lib; };
#     secrets = optSec.mkSecrets {
#       cloudflare-api-key.file = ./secrets/cloudflare.age;
#       technitium-api-key = {
#         file = ./secrets/technitium.age;
#         mode = "0444";
#       };
#     };
#   in {
#     age.secrets = secrets.definitions;
#     environment.variables.API_KEY = secrets.pathIf "technitium-api-key";
#   }

{ lib }:

rec {
  # Check if a secret file exists at evaluation time
  exists = file: builtins.pathExists file;

  # Create a single optional secret
  # Returns: { definition, exists, path, pathOr }
  mkSecret = name: {
    file,
    owner ? "root",
    group ? "root",
    mode ? "0400",
    path ? "/run/agenix/${name}",
    ...
  }@args:
  let
    secretExists = exists file;
    extraArgs = builtins.removeAttrs args [ "file" "owner" "group" "mode" "path" ];
  in {
    inherit name;
    exists = secretExists;
    path = if secretExists then path else null;

    # The age.secrets.<name> definition (empty attrset if file missing)
    definition = lib.mkIf secretExists ({
      inherit file owner group mode path;
    } // extraArgs);

    # Helper: return path if secret exists, else fallback
    pathOr = fallback: if secretExists then path else fallback;

    # Helper: wrap a value with mkIf based on secret existence
    ifExists = value: lib.mkIf secretExists value;
  };

  # Create multiple optional secrets at once
  # Input: { secretName = { file, owner?, mode?, ... }; ... }
  # Output: { definitions, get, pathIf, ifExists, allExist, anyExist }
  mkSecrets = secretDefs:
  let
    processed = lib.mapAttrs mkSecret secretDefs;
  in {
    # age.secrets attrset - merge directly into age.secrets
    definitions = lib.mapAttrs (_: s: s.definition) processed;

    # Get a specific secret's metadata
    get = name: processed.${name} or (throw "Unknown secret: ${name}");

    # Check if a specific secret exists
    exists = name: (processed.${name} or { exists = false; }).exists;

    # Get path if exists, else null
    path = name: (processed.${name} or { path = null; }).path;

    # Get path wrapped in mkIf - use for options that shouldn't be set when secret missing
    pathIf = name:
      let s = processed.${name} or null;
      in if s != null then s.ifExists s.path else null;

    # Wrap any value with mkIf based on secret existence
    ifExists = name: value:
      let s = processed.${name} or null;
      in if s != null && s.exists then lib.mkIf true value else lib.mkIf false value;

    # Check if all defined secrets exist
    allExist = lib.all (s: s.exists) (lib.attrValues processed);

    # Check if any defined secrets exist
    anyExist = lib.any (s: s.exists) (lib.attrValues processed);

    # Raw processed secrets for advanced usage
    _raw = processed;
  };
}
