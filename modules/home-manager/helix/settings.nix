
{
  theme = "ao";

  editor = {
    cursor-shape = {
      insert = "bar";
      normal = "block";
      select = "underline";
    };
    popup-border = "all";
    "auto-pairs" = {
      "(" = ")";
      "{" = "}";
      "[" = "]";
      "\"" = "\"";
      "`" = "`";
      "<" = ">";
      "'" = "'";
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

    line-number = "relative"; # New
    cursorline = true; # New
    bufferline = "multiple"; # Same as original, kept
    scrolloff = 8; # New
    color-modes = true; # Same as original, kept
    true-color = true; # New
    undercurl = true; # New
    jump-label-alphabet = "hatesincludorkmjfxwypgvb"; # New
    end-of-line-diagnostics = "hint"; # Same as original, kept
    rulers = [ 80 120 ]; # New

    lsp = {
      display-messages = true; # Kept from original
      display-inlay-hints = true; # Same as original, kept
      display-progress-messages = true; # Same as original, kept
      goto-reference-include-declaration = false; # New
    };

    statusline = {
      left = [
        "mode"
        "spinner"
        "read-only-indicator"
        "file-modification-indicator"
      ];
      center = [ "file-name" "version-control" ];
      right = [
        "diagnostics"
        "selections"
        "position"
        "file-encoding"
        "file-line-ending"
        "file-type"
      ];
      separator = "│";
      mode = {
        normal = "NORMAL";
        insert = "INSERT";
        select = "SELECT";
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

    "inline-diagnostics" = { 
      cursor-line = "warning";
    };
  };

  keys = {
    normal = {
      H = ":buffer-previous";
      L = ":buffer-next";
      X = "select_line_above";
      "C-h" = "jump_view_left";
      "C-l" = "jump_view_right";
      "C-k" = "page_cursor_half_up";
      "C-j" = "page_cursor_half_down";
      ret = "goto_word";

      m = {
        n = {
          "(" = "@s\\(<ret>nmim";
          "{" = "@s\\{<ret>nmim";
          "[" = "@s\\[<ret>nmim";
          "\"" = "@s\\\"<ret>nmim";
          "'" = "@s\\'<ret>nmim";
          "<" = "@s<lt><ret>nmim";
        };
        p = {
          "(" = "@s\\)<ret>Nmmmim";
          "{" = "@s\\}<ret>Nmmmim";
          "[" = "@s\\]<ret>Nmmmim";
          "\"" = "@s\\\"<ret>Nmmmim";
          "'" = "@s\\'<ret>Nmmmim";
          "<" = "@s<gt><ret>Nmmmim";
        };
      };

      space = { # 'space' key as a prefix
        space = "file_picker"; # maps 'space' then 'space'
        e = [ # maps 'space' then 'e' (Yazi)
          ":sh rm -f /tmp/unique-file"
          ":insert-output yazi %{buffer_name} --chooser-file=/tmp/unique-file"
          # Using \u001b for \x1b escape codes
          ":insert-output echo \"\u001b[?1049h\u001b[?2004h\" > /dev/tty"
          ":open %sh{cat /tmp/unique-file}"
          ":redraw"
          ":set mouse false"
          ":set mouse true"
        ];
        g = [ # maps 'space' then 'g' (Lazygit)
          ":write-all"
          ":insert-output lazygit >/dev/tty"
          ":redraw"
          ":set mouse false"
          ":set mouse true"
          ":reload-all"
        ];
        k = [ # maps 'space' then 'k' (k9s)
          ":write-all"
          ":insert-output k9s >/dev/tty"
          ":redraw"
          ":set mouse false"
          ":set mouse true"
          ":reload-all"
        ];
      };

      backspace = { # 'backspace' key as a prefix
        backspace = "suspend"; # maps 'backspace' then 'backspace'
      };
    };

    insert = {
      "C-h" = [ "jump_view_left" "insert_mode" ];
      "C-l" = [ "jump_view_right" "insert_mode" ];
    };

    select = {
      ret = "extend_to_word";
      X = "select_line_above";
    };
  };
}
