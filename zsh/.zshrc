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
# Binarios locales y herramientas
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Antigravity IDE
if [ -d "/Users/dannielnavas/.antigravity-ide/antigravity-ide/bin" ]; then
  export PATH="/Users/dannielnavas/.antigravity-ide/antigravity-ide/bin:$PATH"
fi

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
# 3. ASISTENTE LOCAL DE IA: NACEL (PLUGIN MODULAR ZSH)
# ==============================================================================
export NACEL_MODEL="${NACEL_MODEL:-${DILIX_MODEL:-gemma2:2b}}"
export NACEL_AUTO_MODE="${NACEL_AUTO_MODE:-${DILIX_AUTO_MODE:-ask}}"

# Cargar plugin modular de Nacel (funciones, autocompletado _nacel, hooks y keybindings)
NACEL_PLUGIN_PATH="$HOME/dotfiles/zsh/plugins/nacel"
if [ ! -d "$NACEL_PLUGIN_PATH" ] && [ -d "$HOME/nacel" ]; then
  NACEL_PLUGIN_PATH="$HOME/nacel"
fi

if [ -d "$NACEL_PLUGIN_PATH" ]; then
  fpath=("$NACEL_PLUGIN_PATH" $fpath)
  source "$NACEL_PLUGIN_PATH/nacel.plugin.zsh"
fi

# Inicializar sistema de autocompletado de Zsh
autoload -Uz compinit
compinit -C 2>/dev/null || compinit


# ==============================================================================
# 4. HERRAMIENTAS INTERACTIVAS (HISTORIAL, FZF, ZOXIDE)
# ==============================================================================
# Atuin: historial enriquecido
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
fi

# fzf: buscador interactivo (macOS / CachyOS / Arch / Linux)
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
elif [ -f /usr/share/fzf/key-bindings.zsh ]; then
  source /usr/share/fzf/key-bindings.zsh
  [ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
fi

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
# 6. PLUGINS DE LÍNEA DE COMANDOS (MACOS / CACHYOS / ARCH / UBUNTU)
# ==============================================================================
# zsh-autosuggestions
for _plugin in \
  "$(brew --prefix 2>/dev/null)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
  if [ -f "$_plugin" ]; then
    source "$_plugin"
    break
  fi
done

# zsh-syntax-highlighting
for _plugin in \
  "$(brew --prefix 2>/dev/null)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
  if [ -f "$_plugin" ]; then
    source "$_plugin"
    break
  fi
done

# zsh-history-substring-search (CachyOS / Arch / Homebrew)
for _plugin in \
  "$(brew --prefix 2>/dev/null)/share/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  "/usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"; do
  if [ -f "$_plugin" ]; then
    source "$_plugin"
    bindkey '^[[A' history-substring-search-up 2>/dev/null || true
    bindkey '^[[B' history-substring-search-down 2>/dev/null || true
    break
  fi
done
unset _plugin

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

# ==============================================================================
# 8. INTEGRACIONES Y ALIASES PARA CACHYOS / ARCH LINUX
# ==============================================================================
if command -v pacman &>/dev/null; then
  # Gestión rápida con Pacman
  alias pac="sudo pacman"
  alias pacin="sudo pacman -S --needed"
  alias pacup="sudo pacman -Syu"
  alias pacrm="sudo pacman -Rns"
  alias pacs="pacman -Ss"
  alias pacq="pacman -Q"
  alias pacorph="sudo pacman -Rns \$(pacman -Qtdq) 2>/dev/null || echo 'No hay paquetes huérfanos / No orphan packages.'"

  # Gestión con AUR Helper (Paru predeterminado en CachyOS, o Yay)
  if command -v paru &>/dev/null; then
    alias p="paru"
    alias pin="paru -S --needed"
    alias pup="paru -Syu"
    alias prm="paru -Rns"
    alias ps="paru -Ss"
  elif command -v yay &>/dev/null; then
    alias y="yay"
    alias yin="yay -S --needed"
    alias yup="yay -Syu"
    alias yrm="yay -Rns"
    alias ys="yay -Ss"
  fi

  # Herramientas exclusivas del ecosistema CachyOS
  if command -v cachyos-rate-mirrors &>/dev/null; then
    alias ratemirrors="sudo cachyos-rate-mirrors"
  fi
  if command -v cachyos-kernel-manager &>/dev/null; then
    alias kernelmgr="cachyos-kernel-manager"
  fi
  if command -v chwd &>/dev/null; then
    alias hwinfo="chwd --list"
  fi
  if command -v cachyos-bugreport &>/dev/null; then
    alias cachyreport="cachyos-bugreport"
  fi
fi

# ==============================================================================
# 9. INTEGRACIONES Y ALIASES PARA UBUNTU / DEBIAN
# ==============================================================================
if command -v apt &>/dev/null; then
  alias aptin="sudo apt update && sudo apt install -y"
  alias aptup="sudo apt update && sudo apt upgrade -y"
  alias aptrm="sudo apt remove --purge -y"
  alias apts="apt search"
  alias aptclean="sudo apt autoremove -y && sudo apt clean"
fi

# ==============================================================================
# 10. INTEGRACIONES Y UTILIDADES PARA WSL2 (WINDOWS SUBSYSTEM FOR LINUX)
# ==============================================================================
if [[ -n "$WSL_DISTRO_NAME" ]] || grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
  export IS_WSL=1

  # Apertura de archivos o URLs en el navegador/aplicación de Windows
  if command -v wslview &>/dev/null; then
    alias open="wslview"
  elif command -v cmd.exe &>/dev/null; then
    alias open="cmd.exe /c start"
  fi

  # Integración de explorador y portapapeles de Windows
  command -v explorer.exe &>/dev/null && alias explore="explorer.exe ."
  command -v clip.exe &>/dev/null && alias clip="clip.exe"
fi

# ==============================================================================
# 11. INFORMACIÓN DEL SISTEMA: FASTFETCH (MACOS, CACHYOS, UBUNTU, WSL2)
# ==============================================================================
alias ff="fastfetch"
alias sysinfo="fastfetch"
alias ff-logo="fastfetch -c config-macos-logo.jsonc"
alias ff-animal="fastfetch -c config-macos-animal.jsonc"
alias ff-pokemon="fastfetch -c config-macos-pokemon.jsonc"

# Ejecutar banner Fastfetch en sesiones de terminal interactivas
if command -v fastfetch &>/dev/null && [[ -o interactive ]] && [[ -t 1 ]]; then
  fastfetch
fi


