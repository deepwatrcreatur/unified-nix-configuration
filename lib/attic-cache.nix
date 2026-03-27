let
  cacheTrust = import ./cache-trust.nix;
in
{
  serverName = "attic-cache";
  serverEndpoint = "http://attic-cache:5001";
  cacheName = "cache-local";
  binaryCacheUrl = "http://attic-cache:5001/cache-local";
  nixCiUrl = "https://cache.nix-ci.com";
  nixosCacheUrl = "https://cache.nixos.org";

  defaultSubstituters =
    { includeNixCi ? false }:
    [
      "http://attic-cache:5001/cache-local"
    ]
    ++ (if includeNixCi then [ "https://cache.nix-ci.com" ] else [ ])
    ++ [ "https://cache.nixos.org" ];

  defaultTrustedPublicKeys =
    { includeNixCi ? false }:
    cacheTrust.cacheLocal
    ++ (if includeNixCi then cacheTrust.nixCi else [ ])
    ++ [ (builtins.head cacheTrust.official) ];
}
