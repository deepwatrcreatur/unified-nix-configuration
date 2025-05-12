{
  theme = "ao";

  editor = {
    cursor-shape = {
      insert = "bar";
      normal = "block";
      select = "underline";
    };
    lsp = {
      display-messages = true;
      display-inlay-hints = true;
      display-progress-messages = true;
    };

    bufferline = "multiple";
    color-modes = true;
    popup-border = "all";
    end-of-line-diagnostics = "hint";

    statusline = {
      left = [ "mode" ];
      center = [
        "version-control"
        "spinner"
        "file-name"
        "read-only-indicator"
        "file-modification-indicator"
      ];
      right = [
        "total-line-numbers"
        "diagnostics"
        "selections"
        "register"
        "position"
        "file-encoding"
        "separator"
      ];
      separator = "▽";
      mode = {
        normal = "(„• ᴗ •„)";
        insert = "(｡•̀ᴗ-)✧☆*:・ﾟ";
        select = "｡ﾟ･ (>﹏<) ･ﾟ｡";
      };
    };

    # Keys with hyphens need quotes
    "auto-pairs" = {
      "(" = ")";
      "{" = "}";
      "[" = "]";
      "\"" = "\""; # Quote the double quote character
      "`" = "`";
      "<" = ">";
      "'" = "'"; # Quote the single quote character
    };

    "auto-save".after-delay = {
      enable = true;
      timeout = 3000;
    };

    whitespace = {
      render = {
        space = "all";
        tab = "all";
        nbsp = "all";
        nnbsp = "all";
        newline = "none";
        tabpad = "all";
      };
      characters = {
        space = "·";
        nbsp = "⍽";
        nnbsp = "␣";
        tab = "→";
        newline = "⏎";
        tabpad = "·";
      };
    };

    "indent-guides" = {
      render = true;
      character = "╎";
      skip-levels = 1;
    };

    "soft-wrap" = {
      enable = true;
      max-wrap = 25;
      max-indent-retain = 0;
      wrap-indicator = "";
    };

    "inline-diagnostics" = { cursor-line = "warning"; };
  };
}

