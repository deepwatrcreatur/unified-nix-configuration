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

    line-number = "relative";
    cursorline = true;
    bufferline = "multiple";
    scrolloff = 8;
    color-modes = true;
    true-color = true;
    undercurl = true;
    jump-label-alphabet = "hatesincludorkmjfxwypgvb";
    end-of-line-diagnostics = "hint";
    rulers = [ 80 120 ];

    lsp = {
      display-messages = true;
      display-inlay-hints = true;
      display-progress-messages = true;
      goto-reference-include-declaration = false;
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

      space = {
        space = "file_picker";
        e = [
          ":sh rm -f /tmp/unique-file"
          ":insert-output yazi %{

buffer_name} --chooser-file=/tmp/unique-file"
          ":insert-output echo \"\u001b[?1049h\u001b[?2004h\" > /dev/tty"
          ":open %sh{cat /tmp/unique-file}"
          ":redraw"
          ":set mouse false"
          ":set mouse true"
        ];
        g = [
          ":write-all"
          ":insert-output lazygit >/dev/tty"
          ":redraw"
          ":set mouse false"
          ":set mouse true"
          ":reload-all"
        ];
        k = [
          ":write-all"
          ":insert-output k9s >/dev/tty"
          ":redraw"
          ":set mouse false"
          ":set mouse true"
          ":reload-all"
        ];
      };

      backspace = {
        backspace = "suspend";
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
