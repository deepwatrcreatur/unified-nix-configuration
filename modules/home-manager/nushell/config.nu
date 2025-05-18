# Your Nushell config here
let-env PATH = ($env.HOME + "/.nix-profile/bin:" + $env.PATH)
let-env EDITOR = "hx"
let-env VISUAL = "hx"

alias ls = lsd
alias ll = lsd -l
alias la = lsd -a
alias lla = lsd -la
alias .. = cd ..
alias update = darwin-rebuild switch --flake $"($env.HOME)/nix-darwin-config/#($nu.env.HOSTNAME)"

let-env PROMPT_COMMAND = {|| starship prompt }
let-env PROMPT_COMMAND_RIGHT = {|| starship prompt --right }

