{
  description = "Private NixCI safe worker extension for Emerald";

  inputs = {
    unified.url = "path:..";

    nix-ci = {
      url = "git+ssh://git@github.com/NorfairKing/nix-ci?rev=6bcbe5a5bdc7b8afc16ef486f107330cae0b5fad";
      inputs.nixpkgs.follows = "unified/nixpkgs";
    };
  };

  outputs = { unified, nix-ci, ... }: {
    nixosConfigurations.emerald = unified.lib.withNixCiWorker nix-ci;
  };
}
