# overlays/cosmic.nix
# COSMIC desktop packages from nixos-cosmic
{ inputs, commonNixpkgsConfig }:

[
  inputs.nixos-cosmic.overlays.default
  (final: prev: {
    cosmic-greeter = prev.cosmic-greeter.overrideAttrs (old: {
      src = old.src.overrideAttrs (_: {
        outputHash = "sha256-ERytoauws6FDJNXItflOE2MwjxwariiO8RXU1x1chkE=";
      });
    });
    cosmic-edit = prev.cosmic-edit.overrideAttrs (old: {
      src = old.src.overrideAttrs (_: {
        outputHash = "sha256-GN1Zts+v3ARcrkN+ZkMUSGNOAlIhXSYWRtWAyqUfUrY=";
      });
    });
    cosmic-comp = prev.cosmic-comp.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.pkg-config ];
      buildInputs = (old.buildInputs or [ ]) ++ [ prev.libdisplay-info_0_2 ];
    });
  })
]
