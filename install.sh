#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPOCK_MODEL="qwen2.5-coder:1.5b"
SPOCK_CONFIG_DIR="$HOME/.config/spock"

# ==============================================================================
# DETECCIÓN AUTOMÁTICA DEL SISTEMA OPERATIVO
# ==============================================================================
DETECTED_CHOICE=""
DETECTED_NAME=""

if [[ "$OSTYPE" == "darwin"* ]]; then
  DETECTED_CHOICE="1"
  DETECTED_NAME="macOS"
elif [ -n "$WSL_DISTRO_NAME" ] || grep -qi microsoft /proc/version 2>/dev/null; then
  DETECTED_CHOICE="4"
  DETECTED_NAME="Windows 11 - WSL2"
elif [ -f /etc/os-release ]; then
  # Arch / CachyOS / Ubuntu / Debian detection
  . /etc/os-release
  if [[ "$ID" == "cachyos" || "$ID" == "arch" || "$ID_LIKE" =~ "arch" || "$ID_LIKE" =~ "cachyos" ]]; then
    DETECTED_CHOICE="2"
    DETECTED_NAME="CachyOS / Arch Linux"
  elif [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" =~ "debian" ]]; then
    DETECTED_CHOICE="3"
    DETECTED_NAME="Linux (Ubuntu / Debian)"
  fi
fi

echo "=========================================="
echo "  🚀 Instalador de Dotfiles & Entorno"
echo "  🖖 Incluye suite completa de Spock AI"
echo "=========================================="
if [ -n "$DETECTED_NAME" ]; then
  echo "🔍 Sistema detectado: $DETECTED_NAME"
fi
echo "Selecciona el entorno en el que deseas instalar:"
echo "  1) macOS"
echo "  2) CachyOS / Arch Linux"
echo "  3) Linux (Ubuntu / Debian)"
echo "  4) Windows 11 - WSL2"
echo "=========================================="

PROMPT_TEXT="Ingresa una opción [1-4]"
if [ -n "$DETECTED_CHOICE" ]; then
  PROMPT_TEXT="$PROMPT_TEXT (por defecto $DETECTED_CHOICE): "
else
  PROMPT_TEXT="$PROMPT_TEXT: "
fi

read -rp "$PROMPT_TEXT" OS_CHOICE
OS_CHOICE="${OS_CHOICE:-$DETECTED_CHOICE}"

case "$OS_CHOICE" in
  1) TARGET_OS="macos" ;;
  2) TARGET_OS="cachyos" ;;
  3) TARGET_OS="linux" ;;
  4) TARGET_OS="wsl2" ;;
  *)
    echo "❌ Opción no válida. Cancelando instalación."
    exit 1
    ;;
esac

echo "➡️ Configurando para: $TARGET_OS..."

# ==============================================================================
# 1. INSTALACIÓN DE PAQUETES Y HERRAMIENTAS
# ==============================================================================
mkdir -p "$HOME/.local/bin" "$HOME/.config"

if [ "$TARGET_OS" = "macos" ]; then
  if ! xcode-select -p &>/dev/null; then
    echo "📦 Instalando Xcode Command Line Tools..."
    xcode-select --install
    echo "Presiona Enter cuando termine la instalación en ventana..."
    read -r
  fi

  if ! command -v brew &>/dev/null; then
    echo "🍺 Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -f "/opt/homebrew/bin/brew" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi

  echo "📦 Instalando herramientas vía Homebrew..."
  brew install \
    wezterm \
    starship \
    atuin \
    ollama \
    python3 \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zoxide \
    fzf \
    eza \
    bat \
    gh

  brew install --cask font-jetbrains-mono-nerd-font || true

elif [ "$TARGET_OS" = "cachyos" ]; then
  echo "📦 Configurando CachyOS / Arch Linux..."
  
  # Determinar gestor de paquetes (paru o pacman)
  AUR_HELPER=""
  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
  elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
  fi

  echo "🔄 Sincronizando repositorios e instalando paquetes base..."
  ARCH_PKGS=(
    zsh
    curl
    git
    fzf
    bat
    base-devel
    wget
    python
    python-pip
    starship
    atuin
    zoxide
    eza
    zsh-autosuggestions
    zsh-syntax-highlighting
    wezterm
    github-cli
    ttf-jetbrains-mono-nerd
    wl-clipboard
    xclip
  )

  sudo pacman -Sy --needed --noconfirm "${ARCH_PKGS[@]}" || {
    echo "⚠️ Algunos paquetes fallaron en lote, instalando individualmente..."
    for pkg in "${ARCH_PKGS[@]}"; do
      sudo pacman -S --needed --noconfirm "$pkg" || echo "⚠️ Falló $pkg, continuando..."
    done
  }

  # Ollama en CachyOS / Arch
  if ! command -v ollama &>/dev/null; then
    echo "🤖 Instalando Ollama..."
    sudo pacman -S --needed --noconfirm ollama || {
      if [ -n "$AUR_HELPER" ]; then
        $AUR_HELPER -S --needed --noconfirm ollama || true
      else
        curl -fsSL https://ollama.com/install.sh | sh || true
      fi
    }
  fi

elif [ "$TARGET_OS" = "linux" ] || [ "$TARGET_OS" = "wsl2" ]; then
  echo "📦 Actualizando apt e instalando herramientas base..."
  sudo apt update && sudo apt install -y \
    zsh \
    curl \
    git \
    fzf \
    bat \
    build-essential \
    wget \
    gpg \
    python3 \
    python3-pip \
    python3-venv \
    wl-clipboard \
    xclip || true

  ln -sf /usr/bin/batcat "$HOME/.local/bin/bat" || true

  # Starship
  if ! command -v starship &>/dev/null; then
    echo "⭐ Instalando Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi

  # Atuin
  if ! command -v atuin &>/dev/null; then
    echo "📜 Instalando Atuin..."
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash
  fi

  # Zoxide
  if ! command -v zoxide &>/dev/null; then
    echo "📂 Instalando Zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  fi

  # eza
  if ! command -v eza &>/dev/null; then
    echo "📁 Instalando eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg || true
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo apt update && sudo apt install -y eza || true
  fi

  sudo apt install -y zsh-autosuggestions zsh-syntax-highlighting || true

  # Ollama
  if ! command -v ollama &>/dev/null; then
    echo "🤖 Instalando Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh || true
  fi
fi

# ==============================================================================
# 2. CONFIGURACIÓN E INSTALACIÓN DEL SISTEMA SPOCK AI
# ==============================================================================
echo ""
echo "=========================================="
echo "  🖖 Configurando Sistema Spock AI"
echo "=========================================="

# Permisos ejecutables para el script de Spock
chmod +x "$DOTFILES_DIR/zsh/spock.py"

# Enlace directo en ~/.local/bin/spock para ejecución global
ln -sf "$DOTFILES_DIR/zsh/spock.py" "$HOME/.local/bin/spock"
echo "✅ Enlace ejecutable creado: $HOME/.local/bin/spock"

# Configuración persistente e idioma de Spock
mkdir -p "$SPOCK_CONFIG_DIR"
CONFIG_FILE="$SPOCK_CONFIG_DIR/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo ""
  echo "🌐 Selecciona el idioma predeterminado para Spock:"
  echo "  1) Español (predeterminado)"
  echo "  2) English"
  read -rp "Opción [1-2] (Enter para Español): " SPOCK_LANG_CHOICE

  if [ "$SPOCK_LANG_CHOICE" = "2" ]; then
    echo '{"lang": "en"}' > "$CONFIG_FILE"
    echo "✅ Spock configurado en idioma Inglés (~/.config/spock/config.json)."
  else
    echo '{"lang": "es"}' > "$CONFIG_FILE"
    echo "✅ Spock configurado en idioma Español (~/.config/spock/config.json)."
  fi
else
  echo "ℹ️ Configuración existente de Spock detectada en $CONFIG_FILE."
fi

# Iniciar o verificar el servicio Ollama
echo "🔌 Verificando servicio de Ollama..."
if ! curl -s http://localhost:11434/api/tags &>/dev/null; then
  echo "⚡ Iniciando Ollama en segundo plano..."
  if [ "$TARGET_OS" = "macos" ]; then
    brew services start ollama 2>/dev/null || nohup ollama serve >/dev/null 2>&1 &
  else
    sudo systemctl enable --now ollama 2>/dev/null || nohup ollama serve >/dev/null 2>&1 &
  fi

  echo "⏳ Esperando respuesta del motor Ollama..."
  OLLAMA_UP=0
  for i in {1..20}; do
    if curl -s http://localhost:11434/api/tags &>/dev/null; then
      OLLAMA_UP=1
      break
    fi
    sleep 1
  done

  if [ $OLLAMA_UP -eq 1 ]; then
    echo "✅ Ollama está listo y respondiendo."
  else
    echo "⚠️ Ollama no respondió a tiempo. Puedes iniciarlo manualmente con 'ollama serve'."
  fi
else
  echo "✅ Servicio Ollama ya se encuentra activo."
fi

# Descarga y verificación del modelo de IA para Spock
if command -v ollama &>/dev/null; then
  echo "🧠 Verificando modelo de IA de Spock ($SPOCK_MODEL)..."
  if ollama list 2>/dev/null | grep -q "$SPOCK_MODEL"; then
    echo "✅ Modelo $SPOCK_MODEL ya disponible en Ollama."
  else
    echo "📥 Descargando modelo $SPOCK_MODEL para Spock (esto puede tardar unos minutos según tu conexión)..."
    ollama pull "$SPOCK_MODEL" || {
      echo "⚠️ No se pudo completar la descarga automática. Ejecuta 'ollama pull $SPOCK_MODEL' cuando tengas conexión."
    }
  fi
fi

# ==============================================================================
# 3. VINCULAR DOTFILES (SYMLINKS)
# ==============================================================================
echo ""
echo "🔗 Creando enlaces simbólicos de Dotfiles..."
rm -f ~/.zshrc ~/.wezterm.lua ~/.config/starship.toml

# Zsh
ln -sf "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc
echo "  ✔ ~/.zshrc -> $DOTFILES_DIR/zsh/.zshrc"

# Starship
if [ -f "$DOTFILES_DIR/startship/starship.toml" ]; then
  ln -sf "$DOTFILES_DIR/startship/starship.toml" ~/.config/starship.toml
  echo "  ✔ ~/.config/starship.toml -> $DOTFILES_DIR/startship/starship.toml"
fi

# WezTerm
if [ "$TARGET_OS" = "macos" ]; then
  ln -sf "$DOTFILES_DIR/wezterm/.wezterm.lua" ~/.wezterm.lua
  echo "  ✔ ~/.wezterm.lua -> $DOTFILES_DIR/wezterm/.wezterm.lua"
elif [ "$TARGET_OS" = "cachyos" ] || [ "$TARGET_OS" = "linux" ]; then
  mkdir -p ~/.config/wezterm
  ln -sf "$DOTFILES_DIR/wezterm/.wezterm.lua" ~/.wezterm.lua
  ln -sf "$DOTFILES_DIR/wezterm/.wezterm.lua" ~/.config/wezterm/wezterm.lua
  echo "  ✔ ~/.wezterm.lua & ~/.config/wezterm/wezterm.lua -> $DOTFILES_DIR/wezterm/.wezterm.lua"
else
  # AUTOMATIZACIÓN EN WINDOWS DESDE WSL2:
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d "\r")
  WIN_HOME="/mnt/c/Users/$WIN_USER"
  DISTRO="${WSL_DISTRO_NAME:-Ubuntu}"

  if [ -d "$WIN_HOME" ]; then
    echo "🪟 Configurando enlace automático para WezTerm en Windows ($WIN_HOME)..."
    cat << EOF > "$WIN_HOME/.wezterm.lua"
return dofile([[\\\\wsl.localhost\\$DISTRO\\home\\$USER\\dotfiles\\wezterm\\.wezterm.lua]])
EOF
    echo "✅ Archivo .wezterm.lua generado en Windows vinculado a WSL2."
  else
    echo "⚠️ No se pudo ubicar $WIN_HOME. Configura el archivo puente en Windows manualmente."
  fi
fi

# ==============================================================================
# 4. FINALIZAR Y COMPILAR
# ==============================================================================
if command -v zcompile &>/dev/null; then
  zcompile ~/.zshrc || true
fi

echo ""
echo "============================================================"
echo "  🎉 ¡Instalación completa para $TARGET_OS!"
echo "  🖖 El sistema Spock está 100% operativo."
echo "============================================================"
echo "Comandos y funciones de Spock disponibles:"
echo "  • spock                    -> Abre el canal de chat interactivo"
echo "  • spock \"<consulta>\"       -> Sugiere comandos o resuelve dudas"
echo "  • ask \"<consulta>\"         -> Sugiere comandos y permite ejecutarlos"
echo "  • fix  (o Ctrl + G)        -> Diagnostica y corrige el último error"
echo "  • spock explain <archivo>  -> Explica arquitectura y código"
echo "  • spock debug <error>      -> Deduce causa raíz y anomalías"
echo "  • spock lang [es|en]       -> Cambia el idioma en cualquier momento"
echo "============================================================"
echo "Ejecuta 'exec zsh' o reinicia tu terminal para comenzar."
