let
  cacheTrust = import ./cache-trust.nix;
in rec {
  serverName = "attic-cache";
  serverEndpoint = "http://attic-cache:5001";
  cacheName = "cache-local";
  binaryCacheUrl = "http://attic-cache:5001/cache-local";
  # Fallback IP for when DNS is down
  binaryCacheIpUrl = "http://10.10.11.39:5001/cache-local";
  nixCiUrl = "https://cache.nix-ci.com";
  nixosCacheUrl = "https://cache.nixos.org";

  # Public caches that should be available to agents
  secondarySubstituters = [
    "https://cache.numtide.com"
    "https://cuda-maintainers.cachix.org"
    "https://cache.garnix.io/"
    "https://nix-community.cachix.org/"
    "https://hyprland.cachix.org/"
  ];

  defaultSubstituters =
    { includeNixCi ? false }:
    [
      "http://attic-cache:5001/cache-local"
      "http://10.10.11.39:5001/cache-local" # DNS fallback
    ]
    ++ (if includeNixCi then [ "https://cache.nix-ci.com" ] else [ ])
    ++ [ "https://cache.nixos.org" ]
    ++ secondarySubstituters;

  defaultTrustedPublicKeys =
    { includeNixCi ? false }:
    cacheTrust.cacheLocal
    ++ (if includeNixCi then cacheTrust.nixCi else [ ])
    ++ cacheTrust.official;
}
