# modules/home-manager/common/file-aliases.nix
# File and directory listing aliases
{
  config,
  lib,
  ...
}:
let
  # File listing and navigation aliases
  fileAliases = {
    # LSD aliases (if available)
    ls = "lsd";
    ll = "lsd -l";
    la = "lsd -a";
    lla = "lsd -la";

    # FD aliases (enhanced find)
    fda = "fd --hidden --no-ignore";
    fdaud = "fd -e mp3 -e wav -e flac -e aac -e ogg";
    fdcode = "fd -e py -e js -e ts -e rs -e go -e c -e cpp -e java";
    fdd = "fd --type directory";
    fddoc = "fd -e pdf -e doc -e docx -e txt -e md";
    fde = "fd --type empty";
    fdf = "fd --type file";
    fdh = "fd --hidden";
    fdi = "fd --no-ignore";
    fdimg = "fd -e jpg -e jpeg -e png -e gif -e bmp -e svg";
    fdl = "fd --type symlink";
    fdm = "fd --changed-within 1month";
    fdn = "fd --changed-within 1day";
    fds = "fd --case-sensitive";
    fdvid = "fd -e mp4 -e avi -e mkv -e mov -e wmv -e flv";
    fdw = "fd --changed-within 1week";
    fdx = "fd --type executable";

    # EZA aliases (alternative to ls)
    lt = "eza --tree";
  };
in
{
  options.custom.fileAliases = {
    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = fileAliases;
      description = "File and directory listing aliases";
      readOnly = true;
    };
  };
}
