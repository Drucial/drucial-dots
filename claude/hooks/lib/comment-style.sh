# comment_style sets STYLE, LINE_RE and LINE_MARK for a path. It returns 1 for a
# file whose comments the rule does not govern, which the caller skips.
comment_style() {
  local BASE EXT
  BASE="$(basename -- "$1")"
  EXT="$(printf '%s' "$BASE" | tr '[:upper:]' '[:lower:]')"
  case "$EXT" in
  *.*) EXT="${EXT##*.}" ;;
  *)   EXT="" ;;
  esac

  STYLE=""     # block-comment grammar: c | py | rb | lua | hs | html | "" (none)
  LINE_RE=""   # awk regex matching a whole-line comment
  LINE_MARK="" # literal characters that open a trailing comment

  case "$EXT" in
  md|mdx|markdown|txt|rst|adoc|json|jsonc|yaml|yml|toml|csv|tsv|lock|log|svg|env)
    return 1 ;;
  js|jsx|ts|tsx|mjs|cjs|mts|cts|c|h|cc|cpp|cxx|hpp|hh|cs|java|kt|kts|swift|go|rs|scala|php|dart|m|mm|zig|proto|gradle|groovy|css|scss|less|sass|glsl|frag|vert)
    STYLE=c;    LINE_RE='^[ \t]*//'; LINE_MARK='//' ;;
  py|pyi)
    STYLE=py;   LINE_RE='^[ \t]*#';  LINE_MARK='#' ;;
  rb|rake|gemspec)
    STYLE=rb;   LINE_RE='^[ \t]*#';  LINE_MARK='#' ;;
  sh|bash|zsh|fish|ksh|pl|pm|nix|tf|hcl|ps1|r|jl|ex|exs|cr|mk)
    STYLE="";   LINE_RE='^[ \t]*#';  LINE_MARK='#' ;;
  lua)
    STYLE=lua;  LINE_RE='^[ \t]*--'; LINE_MARK='--' ;;
  sql)
    STYLE=c;    LINE_RE='^[ \t]*--'; LINE_MARK='--' ;;
  hs|elm)
    STYLE=hs;   LINE_RE='^[ \t]*--'; LINE_MARK='--' ;;
  html|htm|vue|svelte|xml|erb|hbs)
    STYLE=html; LINE_RE='';          LINE_MARK='' ;;
  "")
    case "$BASE" in
      Makefile|makefile|GNUmakefile|Dockerfile|Dockerfile.*|Gemfile|Rakefile|Brewfile|Justfile|justfile|Vagrantfile|Procfile|.zshrc|.bashrc|.zshenv|.profile|.gitconfig)
        STYLE=""; LINE_RE='^[ \t]*#'; LINE_MARK='#' ;;
      *) return 1 ;;
    esac ;;
  *) return 1 ;;
  esac

  return 0
}
