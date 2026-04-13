fish_add_path ~/.local/bin

if status is-interactive
  mise activate fish | source
  try init ~/playground | source
end
