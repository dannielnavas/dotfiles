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
# 2.1 PORTAPAPELES Y COPIA DE COMANDOS / RESULTADOS (ÉXITO Y ERROR)
# ==============================================================================
# Función multiplataforma para copiar texto al portapapeles (macOS, Linux, WSL2, OSC52)
_clipboard_copy() {
  local input
  if [[ $# -gt 0 ]]; then
    input="$*"
  else
    input="$(cat)"
  fi

  if command -v pbcopy &>/dev/null; then
    printf "%s" "$input" | pbcopy
  elif command -v clip.exe &>/dev/null; then
    printf "%s" "$input" | clip.exe
  elif command -v wl-copy &>/dev/null; then
    printf "%s" "$input" | wl-copy
  elif command -v xclip &>/dev/null; then
    printf "%s" "$input" | xclip -selection clipboard
  elif command -v xsel &>/dev/null; then
    printf "%s" "$input" | xsel --clipboard --input
  else
    # Fallback OSC 52 (soportado nativamente por WezTerm)
    local b64
    b64=$(printf "%s" "$input" | base64 | tr -d '\r\n')
    printf "\033]52;c;%s\a" "$b64"
  fi
}

# Registro automático del último comando ejecutado y su código de salida
autoload -Uz add-zsh-hook

__dotfiles_track_preexec() {
  if [[ "$1" != cpcmd* && "$1" != copylast* && "$1" != cpout* && "$1" != copyout* ]]; then
    export __DOTFILES_LAST_CMD="$1"
    export __DOTFILES_CMD_RAN=1
  fi
}

__dotfiles_track_precmd() {
  local exit_code=$?
  if [[ -n "$__DOTFILES_CMD_RAN" ]]; then
    export __DOTFILES_LAST_CODE=$exit_code
    export __DOTFILES_CMD_RAN=""
  fi
}

add-zsh-hook preexec __dotfiles_track_preexec
add-zsh-hook precmd __dotfiles_track_precmd

# Copia el último comando ejecutado o generado (tanto si fue exitoso como si dio error)
cpcmd() {
  local target_cmd="${__DOTFILES_LAST_CMD:-$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')}"
  local last_code="${__DOTFILES_LAST_CODE:-0}"

  if [[ -z "$target_cmd" ]]; then
    echo -e "\033[1;33m⚠️  No hay comando reciente para copiar.\033[0m"
    return 1
  fi

  _clipboard_copy "$target_cmd"
  if [[ "$last_code" -eq 0 ]]; then
    echo -e "\033[1;32m📋 Comando copiado (✔ exitoso):\033[0m $target_cmd"
  else
    echo -e "\033[1;31m📋 Comando copiado (✖ error $last_code):\033[0m $target_cmd"
  fi
}
alias copylast="cpcmd"

# Ejecuta un comando (o el último comando) y copia su salida tanto exitosa (stdout) como de error (stderr)
cpout() {
  local target_cmd
  if [[ $# -gt 0 ]]; then
    target_cmd="$*"
  else
    target_cmd="${__DOTFILES_LAST_CMD:-$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')}"
  fi

  if [[ -z "$target_cmd" ]]; then
    echo -e "\033[1;33m⚠️  No hay comando para ejecutar y copiar su resultado.\033[0m"
    return 1
  fi

  local tmp_out
  tmp_out="$(mktemp -t zsh_cpout.XXXXXX)"
  eval "$target_cmd" > >(tee "$tmp_out") 2> >(tee -a "$tmp_out" >&2)
  local cmd_status=$?

  _clipboard_copy < "$tmp_out"
  rm -f "$tmp_out"

  export __DOTFILES_LAST_CMD="$target_cmd"
  export __DOTFILES_LAST_CODE=$cmd_status

  if [[ $cmd_status -eq 0 ]]; then
    echo -e "\033[1;32m📋 Resultado copiado al portapapeles (✔ exitoso)\033[0m"
  else
    echo -e "\033[1;31m📋 Resultado de error copiado al portapapeles (✖ código $cmd_status)\033[0m"
  fi

  return $cmd_status
}
alias copyout="cpout"

# Atajo de teclado interactivo (Alt+Y / Ctrl+Y) para copiar el último comando al instante
if [[ -o interactive ]]; then
  __dotfiles_copy_cmd_widget() {
    zle -I
    cpcmd
    zle reset-prompt
  }
  zle -N __dotfiles_copy_cmd_widget
  bindkey '^[y' __dotfiles_copy_cmd_widget
fi

# ==============================================================================
# 3. ASISTENTE LOCAL DE IA: NACEL (https://github.com/dannielnavas/nacel)
# ==============================================================================
# export NACEL_MODEL="" # Gestionado automáticamente en ~/.config/nacel/config.json
export NACEL_AUTO_MODE="${NACEL_AUTO_MODE:-ask}"

# Consumir plugin de Nacel (prioridad: desarrollo local ~/nacel > ~/.nacel)
NACEL_DIR="${NACEL_DIR:-$HOME/nacel}"
if [ ! -d "$NACEL_DIR" ] && [ -d "$HOME/.nacel" ]; then
  NACEL_DIR="$HOME/.nacel"
fi

# Autodescarga del plugin si no existe en la máquina
if [ ! -d "$NACEL_DIR" ]; then
  echo "📥 Instalando plugin Nacel AI desde https://github.com/dannielnavas/nacel..."
  git clone --depth 1 https://github.com/dannielnavas/nacel.git "$HOME/.nacel" 2>/dev/null
  NACEL_DIR="$HOME/.nacel"
fi

if [ -d "$NACEL_DIR" ]; then
  fpath=("$NACEL_DIR" $fpath)
  source "$NACEL_DIR/nacel.plugin.zsh"

  # Integrar copia de comandos resultantes de Nacel (tanto en consultas como en errores/fix)
  __nacel_run_action() {
    local action_type="$1"
    local cmd="$2"

    if [[ -n "$cmd" ]]; then
      export __DOTFILES_LAST_CMD="$cmd"
    fi

    case "$action_type" in
      EXEC)
        if [[ -n "$cmd" ]]; then
          print -s "$cmd"
          echo -e "\033[1;32m▶ Running / Ejecutando:\033[0m $cmd"
          eval "$cmd"
          export __DOTFILES_LAST_CODE=$?
        fi
        ;;
      MODIFY)
        if [[ -n "$cmd" ]]; then
          print -z "$cmd"
        fi
        ;;
      COPY)
        if [[ -n "$cmd" ]]; then
          _clipboard_copy "$cmd"
          echo -e "\033[1;32m📋 Copied / Copiado:\033[0m $cmd"
        fi
        ;;
      CANCEL|*)
        ;;
    esac
  }
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

# pnpm
export PNPM_HOME="/Users/dannielnavas/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
