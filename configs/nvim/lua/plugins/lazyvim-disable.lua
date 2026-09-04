-- Omarchy's theme spec names its colorscheme through a LazyVim entry. The
-- symlinked spec must stay imported for lazy's change detection to fire
-- LazyReload on a theme switch, so disable the distro rather than drop the file.
return {
  { "LazyVim/LazyVim", enabled = false },
}
