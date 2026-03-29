# ast-grep (sg)

`ast-grep` (`sg`) is available system-wide via `dev-tools.nix`. Prefer it over `grep`/`ripgrep` for structural code searches — it understands syntax rather than text.

## When to use

- Finding all calls to a function: `sg -p 'foo($ARGS)' .`
- Renaming an identifier across files: `sg -p 'oldName' --rewrite 'newName' .`
- Locating attribute accesses, imports, or patterns that are hard to express as regexes
- Any search where you need to match AST shape, not raw text

## Basic usage

```bash
# Search for a pattern
sg -p 'environment.systemPackages = [$$$]' --lang nix .

# Search and replace
sg -p 'mkIf $COND $BODY' --rewrite 'lib.mkIf $COND $BODY' --lang nix .

# List supported languages
sg --list-languages
```

## Nix-specific notes

Pass `--lang nix` (or `-l nix`) since ast-grep defaults to detecting language from extension, which works fine for `.nix` files but is worth being explicit about.

For multi-line Nix attribute sets, use `$$$` (triple dollar) to match multiple nodes inside a block.
