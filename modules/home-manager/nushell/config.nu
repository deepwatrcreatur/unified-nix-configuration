alias ls = lsd
alias ll = lsd -l
alias la = lsd -a
alias lla = lsd -la
alias .. = cd ..
alias update = darwin-rebuild switch --flake $"($env.HOME)/nix-darwin-config/#($nu.env.HOSTNAME)"

