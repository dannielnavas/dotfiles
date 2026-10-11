# ==============================================================================
# 1. VARIABLES DE ENTORNO Y PATH
# ==============================================================================
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Homebrew environment
if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Antigravity IDE
export PATH="/Users/dannielnavas/.antigravity-ide/antigravity-ide/bin:$PATH"

# ==============================================================================
# 2. ALIASES GENERALES Y DE PRODUCTIVIDAD
# ==============================================================================
# Sistema y recarga
alias reload="exec zsh"
alias c="clear"

# Accesos rápidos a configuración
alias zshconfig="nano ~/.zshrc"
alias wezconfig="nano ~/.wezterm.lua"

# Atajos de Git
alias gs="git status -sb"
alias ga="git add"
alias gaa="git add --all"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gl="git log --oneline --graph --decorate -n 10"

# ==============================================================================
# 3. ASISTENTE LOCAL DE IA (OLLAMA)
# ==============================================================================
ask() {
  if [ -z "$1" ]; then
    echo "Uso: ask \"tu consulta aquí\""
    return 1
  fi
  ollama run qwen2.5-coder:1.5b "Responde únicamente con el comando exacto de terminal para Mac/Linux para hacer lo siguiente, sin explicaciones largas ni markdown: $*"
}

# ==============================================================================
# 4. HERRAMIENTAS INTERACTIVAS (HISTORIAL, FZF, ZOXIDE)
# ==============================================================================
# Atuin: historial enriquecido
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
fi

# fzf: buscador interactivo
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zoxide: reemplazo inteligente de cd
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# ==============================================================================
# 5. PROMPT (STARSHIP)
# ==============================================================================
export STARSHIP_KEYMAP_SELECT=false

if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# ==============================================================================
# 6. PLUGINS DE LÍNEA DE COMANDOS (HOMEBREW)
# ==============================================================================
if [ -f "$(brew --prefix 2>/dev/null)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [ -f "$(brew --prefix 2>/dev/null)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# ==============================================================================
# 7. UTILIDADES MODERNAS (EZA, BAT)
# ==============================================================================
# Reemplazos modernos de ls con eza
if command -v eza &>/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -la --icons --octal-permissions --group-directories-first --git"
  alias lt="eza --tree --level=2 --icons"
  alias tree="eza --tree --icons"
fi

# Reemplazos modernos de cat con bat
if command -v bat &>/dev/null; then
  alias cat="bat --paging=never --style=plain"
  alias preview="bat --style=numbers,changes"
fi
