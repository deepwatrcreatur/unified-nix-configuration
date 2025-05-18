export-env {
  $env.PATH = ($env.PATH | prepend $"($env.HOME)/.nix-profile/bin")
  $env.EDITOR = "hx"
  $env.VISUAL = "hx"
  $env.PROMPT_COMMAND = {|| starship prompt }
  $env.PROMPT_COMMAND_RIGHT = {|| starship prompt --right }
}
