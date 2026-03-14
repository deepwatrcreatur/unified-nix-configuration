{
  pkgs,
  inputs,
}:
[
  {
    id = "claude";
    name = "Claude Code";
    command = "claude";
    package = pkgs.claude-code;
  }
  {
    id = "cursor";
    name = "Cursor Agent";
    command = "cursor-agent";
    package = pkgs.cursor-cli;
  }
  {
    id = "gemini";
    name = "Gemini CLI";
    command = "gemini";
    package = pkgs.gemini-cli;
  }
  {
    id = "copilot";
    name = "GitHub Copilot CLI";
    command = "copilot";
    package = pkgs.github-copilot-cli;
  }
  {
    id = "factory";
    name = "Factory Droid";
    command = "factory-droid";
    package = pkgs.factory-droid;
  }
  {
    id = "codex";
    name = "Codex CLI";
    command = "codex";
    package = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.codex;
  }
]
