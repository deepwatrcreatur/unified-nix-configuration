{
  buildGoModule,
  fetchFromGitHub,
  stdenv,
}:

buildGoModule rec {
  pname = "caddy-dynamicdns";
  version = "master";

  src = fetchFromGitHub {
    owner = "mholt";
    repo = "caddy-dynamicdns";
    rev = "master";
    hash = "sha256-tzR5d4OL6mPKFvZ72jC3gOzbmHnLS2XBNhqejXJ2XaI=";
  };

  vendorHash = "sha256-JS8mF5eDp/3yYq5vjq4K5K7z7p7z7p7p7p7p7p7z7p7p7p7";

  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with stdenv.lib; {
    description = "Dynamic DNS app for Caddy";
    homepage = "https://github.com/mholt/caddy-dynamicdns";
    license = licenses.asl20;
    maintainers = [ ];
    mainProgram = "caddy-dynamicdns";
    platforms = platforms.linux;
  };
}
