{ pkgs }:

{
  language = [
    {
      name = "nix";
      auto-format = true;
      formatter = { command = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt"; args = [ "-" ]; };
      language-servers = [ "nil" "nixd" ];
      soft-wrap.enable = false;
    }
    {
      name = "elixir";
      auto-format = true;
      language-servers = [ "elixir-ls" ];
    }
    {
      name = "yaml";
      auto-format = true;
      language-servers = [ "yaml-language-server" ];
      formatter = { command = "${pkgs.yaml-language-server}/bin/yamlfmt"; args = [ "-in" ]; };
    }
    {
      name = "python";
      auto-format = true;
      language-servers = [ "pyright" ];
      formatter = { command = "${pkgs.black}/bin/black"; args = [ "--quiet" "-" ]; };
    }
    {
      name = "javascript";
      auto-format = true;
      language-servers = [ "typescript-language-server" ];
      formatter = { command = "${pkgs.prettier}/bin/prettier"; args = [ "--parser" "javascript" ]; };
    }
    {
      name = "typescript";
      auto-format = true;
      language-servers = [ "typescript-language-server" ];
      formatter = { command = "${pkgs.prettier}/bin/prettier"; args = [ "--parser" "typescript" ]; };
    }
    {
      name = "go";
      auto-format = true;
      language-servers = [ "gopls" ];
      formatter = { command = "${pkgs.go}/bin/gofmt"; args = [ "-s" ]; };
    }
  ];
  language-server = {
    nil = {
      command = "${pkgs.nil}/bin/nil";
      config.nil = { formatting.command = [ "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt" ]; };
    };

    nixd = { command = "${pkgs.nixd}/bin/nixd"; };

    "elixir-ls" = {
      command = "${pkgs.elixir-ls}/bin/language_server.sh";
    };

    "yaml-language-server" = {
      command = "${pkgs.yaml-language-server}/bin/yaml-language-server";
      args = [ "--stdio" ];
      config.yaml = {
        format.enable = true;
        validation = true;
        keyOrdering = false;
        schemaStore.enable = true;
        schemas = {
          "https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json" = "*gitlab-ci*.{yml,yaml}";
          "https://json.schemastore.org/ansible-playbook" = "*play*.{yml,yaml}";
          "https://json.schemastore.org/ansible-stable-2.9" = "roles/tasks/*.{yml,yaml}";
          "https://json.schemastore.org/chart" = "Chart.{yml,yaml}";
          "https://json.schemastore.org/dependabot-v2" = ".github/dependabot.{yml,yaml}";
          "https://json.schemastore.org/github-action" = ".github/action.{yml,yaml}";
          "https://json.schemastore.org/github-workflow" = ".github/workflows/*";
          "https://json.schemastore.org/prettierrc" = ".prettierrc.{yml,yaml}";
          "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json" = "*api*.{yml,yaml}";
          "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" = "*docker-compose*.{yml,yaml}";
          kubernetes = "*.y{a,}ml";
        };
      };
    };

    pyright = {
      command = "${pkgs.pyright}/bin/pyright-langserver";
      args = [ "--stdio" ];
      config = {
        python.analysis.typeCheckingMode = "basic";
      };
    };

    "typescript-language-server" = {
      command = "${pkgs.typescript-language-server}/bin/typescript-language-server";
      args = [ "--stdio" ];
    };

    gopls = {
      command = "${pkgs.gopls}/bin/gopls";
      config = {
        "formatting.gofumpt" = true;
        "ui.inlayhint.hints" = {
          parameterHints = true;
          typeHints = true;
        };
      };
    };
  };
}
