{ pkgs }: # Accept pkgs as an argument
{
  language = [
    {
      name = "nix";
      auto-format = true;
      formatter = { command = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt"; args = [ "-" ]; };
      language-servers = [ "nil" "nixd" ];
    }
    {
      name = "elixir";
      auto-format = true;
      language-servers = [ "elixir-ls" ];
      # Add formatter if needed for Elixir
      # formatter = { command = "mix"; args = ["format", "-"]; };
    }
    # Add other languages here if needed
  ];
  language-server = {
    nil = {
      command = "${pkgs.nil}/bin/nil"; # Explicit path is good practice
      config.nil = { formatting.command = [ "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt" ]; };
    };

    nixd = { command = "${pkgs.nixd}/bin/nixd"; };

    "elixir-ls" = {
      command = "${pkgs.elixir-ls}/bin/language_server.sh"; # Use the wrapper script
    };
  };
}

