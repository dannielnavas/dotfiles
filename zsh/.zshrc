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
# 3. ASISTENTE LOCAL DE IA: SPOCK (OLLAMA)
# ==============================================================================
export SPOCK_MODEL="qwen2.5-coder:1.5b"

# Modos de comportamiento cuando un comando da error:
#   "ask"  -> Muestra aviso y pregunta si deseas que Spock analice el error [s/N] / [y/N]
#   "auto" -> Analiza automáticamente con Spock cada vez que un comando falle
#   "hint" -> Muestra una barra sutil indicando presionar 'fix', 'spock' o Ctrl+G
export SPOCK_AUTO_MODE="ask"

if [ -z "$__SPOCK_SCRIPT" ]; then
  if [ -f "$HOME/dotfiles/zsh/spock.py" ]; then
    __SPOCK_SCRIPT="$HOME/dotfiles/zsh/spock.py"
  elif [ -f "$HOME/.local/bin/spock" ]; then
    __SPOCK_SCRIPT="$HOME/.local/bin/spock"
  else
    __SPOCK_SCRIPT="$(command -v spock 2>/dev/null || echo "$HOME/dotfiles/zsh/spock.py")"
  fi
fi

# Obtiene el idioma activo (es / en) configurado en Spock
__spock_get_lang() {
  if [ -n "$SPOCK_LANG" ]; then
    echo "$SPOCK_LANG"
    return
  fi
  local cfg="$HOME/.config/spock/config.json"
  if [ -f "$cfg" ]; then
    local l=$(grep -o '"lang": *"[^"]*"' "$cfg" 2>/dev/null | cut -d'"' -f4)
    if [ -n "$l" ]; then
      echo "$l"
      return
    fi
  fi
  echo "es"
}

# Ejecuta o inserta el comando según la acción elegida por el usuario
__spock_run_action() {
  local action_type="$1"
  local cmd="$2"

  case "$action_type" in
    EXEC)
      if [ -n "$cmd" ]; then
        print -s "$cmd" # Agrega al historial de Zsh
        echo -e "\033[1;32m▶ Running / Ejecutando:\033[0m $cmd"
        eval "$cmd"
      fi
      ;;
    MODIFY)
      if [ -n "$cmd" ]; then
        print -z "$cmd" # Carga el comando en el prompt para editarlo
      fi
      ;;
    CANCEL|*)
      ;;
  esac
}

# Consulta en lenguaje natural para obtener comandos
ask() {
  if [ $# -eq 0 ]; then
    local lang=$(__spock_get_lang)
    if [[ "$lang" == "en" ]]; then
      echo -e "\033[1;33mUsage:\033[0m ask \"your natural language query\""
      echo -e "Example: ask \"how to list listening ports\""
    else
      echo -e "\033[1;33mUso:\033[0m ask \"tu consulta aquí\""
      echo -e "Ejemplo: ask \"como ver puertos en uso\""
    fi
    return 1
  fi

  local output
  output=$(python3 "$__SPOCK_SCRIPT" ask "$@")
  local action="${output%%:*}"
  local cmd="${output#*:}"
  __spock_run_action "$action" "$cmd"
}

# Diagnóstico y corrección lógica de errores para comandos fallidos
fix() {
  local target_cmd="${__SPOCK_LAST_CMD:-}"
  local exit_code="${__SPOCK_LAST_CODE:-1}"
  local user_extra="$*"

  if [ -z "$target_cmd" ] && [ -z "$user_extra" ]; then
    local lang=$(__spock_get_lang)
    if [[ "$lang" == "en" ]]; then
      echo -e "\033[1;33m💡 No recent failed commands for Spock to analyze.\033[0m"
    else
      echo -e "\033[1;33m💡 No hay comandos fallidos recientes para que Spock analice.\033[0m"
    fi
    return 0
  fi

  # Reset del flag para evitar bucles
  __SPOCK_CMD_ACTIVE=""

  local output
  output=$(python3 "$__SPOCK_SCRIPT" fix "$target_cmd" "$exit_code" "$user_extra")
  local action="${output%%:*}"
  local cmd="${output#*:}"
  __spock_run_action "$action" "$cmd"
}

# Comando multifunción 'spock': chat, explain, debug, fix, lang y consultas
spock() {
  local spock_py="$__SPOCK_SCRIPT"

  if [ $# -eq 0 ]; then
    # Si el comando previo falló, ofrece repararlo; si no, inicia chat interactivo directo
    if [ -n "$__SPOCK_LAST_CMD" ] && [[ "${__SPOCK_LAST_CODE:-0}" -ne 0 ]]; then
      fix
    else
      python3 "$spock_py" chat
    fi
    return
  fi

  case "$1" in
    lang|language|idioma)
      shift
      python3 "$spock_py" lang "$@"
      ;;
    explain|code)
      shift
      python3 "$spock_py" explain "$@"
      ;;
    debug)
      shift
      python3 "$spock_py" debug "$@"
      ;;
    chat)
      shift
      python3 "$spock_py" chat "$@"
      ;;
    fix)
      shift
      fix "$@"
      ;;
    ask)
      shift
      ask "$@"
      ;;
    help|--help|-h)
      local lang=$(__spock_get_lang)
      if [[ "$lang" == "en" ]]; then
        echo -e "\033[1;35m🖖 Spock - Terminal Copilot & Logical Assistant\033[0m"
        echo -e "  \033[36mspock\033[0m                     -> Start interactive direct communication channel"
        echo -e "  \033[36mspock explain <file|cmd>\033[0m  -> Explain code structure, mechanics & architecture"
        echo -e "  \033[36mspock debug <error|file>\033[0m  -> Debug errors and deduce root cause"
        echo -e "  \033[36mspock fix\033[0m                 -> Diagnose and fix the last failed command"
        echo -e "  \033[36mspock lang [en|es]\033[0m        -> Change language (English / Español)"
        echo -e "  \033[36mspock \"query\"\033[0m             -> Suggest commands or answer technical questions"
        echo -e "  \033[36mCtrl + G\033[0m                  -> Keyboard shortcut to diagnose last error"
      else
        echo -e "\033[1;35m🖖 Spock - Copiloto de Terminal y Programación Lógica\033[0m"
        echo -e "  \033[36mspock\033[0m                     -> Inicia el canal de comunicación interactivo (chat)"
        echo -e "  \033[36mspock explain <archivo|cmd>\033[0m-> Explica código, arquitectura y funcionamiento"
        echo -e "  \033[36mspock debug <error|archivo>\033[0m-> Depura errores y determina la causa raíz"
        echo -e "  \033[36mspock fix\033[0m                 -> Diagnostica el último comando fallido"
        echo -e "  \033[36mspock lang [es|en]\033[0m        -> Cambiar idioma (Español / English)"
        echo -e "  \033[36mspock \"consulta\"\033[0m          -> Sugiere comandos o responde preguntas técnicas"
        echo -e "  \033[36mCtrl + G\033[0m                  -> Atajo para diagnosticar el último error"
      fi
      ;;
    *)
      local output
      output=$(python3 "$spock_py" query "$@")
      local action="${output%%:*}"
      local cmd="${output#*:}"
      if [[ "$action" == "EXEC" || "$action" == "MODIFY" || "$action" == "CANCEL" ]]; then
        __spock_run_action "$action" "$cmd"
      fi
      ;;
  esac
}

# Atajo de teclado (Ctrl+G) para invocar a Spock directamente desde la terminal
if [[ -o interactive ]]; then
  __spock_fix_widget() {
    zle -I
    fix
    zle reset-prompt
  }
  zle -N __spock_fix_widget
  bindkey '^G' __spock_fix_widget
fi

# Hooks automáticos de Zsh para capturar comandos y códigos de salida
__spock_preexec() {
  # No registrar llamadas al propio Spock
  if [[ "$1" != fix* && "$1" != ask* && "$1" != spock* && "$1" != __spock* ]]; then
    export __SPOCK_LAST_CMD="$1"
    export __SPOCK_CMD_ACTIVE=1
  fi
}

__spock_precmd() {
  local last_code=$?
  
  if [[ -n "$__SPOCK_CMD_ACTIVE" ]]; then
    export __SPOCK_LAST_CODE=$last_code
    export __SPOCK_CMD_ACTIVE=""

    # Si el comando falló (exit != 0) y no fue cancelado con Ctrl+C (130) ni suspendido (148)
    if [[ $last_code -ne 0 && $last_code -ne 130 && $last_code -ne 148 ]]; then
      local mode="${SPOCK_AUTO_MODE:-${WARP_AI_AUTO_MODE:-ask}}"
      local lang=$(__spock_get_lang)

      if [[ "$lang" == "en" ]]; then
        case "$mode" in
          auto)
            echo ""
            fix
            ;;
          ask)
            echo ""
            echo -en "\033[31m╭─ ❌ Failed ($last_code)\033[0m \033[33m•\033[0m \033[1;36mAnalyze with Spock? [y/N] (or press Ctrl+G):\033[0m "
            local reply
            if read -t 5 -k 1 reply 2>/dev/null; then
              echo ""
              if [[ "$reply" == "y" || "$reply" == "Y" || "$reply" == "s" || "$reply" == "S" ]]; then
                fix
              fi
            else
              echo ""
            fi
            ;;
          hint|*)
            print -P "%F{red}╭─ ❌ Failed with exit code $last_code%f %F{yellow}•%f %F{cyan}Type %Bspock%b or %Bfix%b to analyze or press %B[Ctrl+G]%b%f"
            ;;
        esac
      else
        case "$mode" in
          auto)
            echo ""
            fix
            ;;
          ask)
            echo ""
            echo -en "\033[31m╭─ ❌ Falló ($last_code)\033[0m \033[33m•\033[0m \033[1;36m¿Analizar con Spock? [s/N] (o pulsa Ctrl+G):\033[0m "
            local reply
            if read -t 5 -k 1 reply 2>/dev/null; then
              echo ""
              if [[ "$reply" == "s" || "$reply" == "S" || "$reply" == "y" || "$reply" == "Y" ]]; then
                fix
              fi
            else
              echo ""
            fi
            ;;
          hint|*)
            print -P "%F{red}╭─ ❌ Falló con código $last_code%f %F{yellow}•%f %F{cyan}Escribe %Bspock%b o %Bfix%b para analizar o pulsa %B[Ctrl+G]%b%f"
            ;;
        esac
      fi
    fi
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec __spock_preexec
add-zsh-hook precmd __spock_precmd

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
