set -g fish_greeting
set -gxp PATH ~/.local/bin

if status is-interactive
  mise activate fish | source
  starship init fish | source
end
