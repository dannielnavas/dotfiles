#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPOCK_MODEL="qwen2.5-coder:1.5b"
SPOCK_CONFIG_DIR="$HOME/.config/spock"

# ==============================================================================
# SELECCIÓN DE IDIOMA / LANGUAGE SELECTION
# ==============================================================================
INSTALL_LANG=""
for arg in "$@"; do
  case "$arg" in
    --en|--english) INSTALL_LANG="en" ;;
    --es|--spanish) INSTALL_LANG="es" ;;
  esac
done

if [ -z "$INSTALL_LANG" ]; then
  echo "=========================================="
  echo "  🌐 Language / Idioma"
  echo "=========================================="
  echo "  1) Español (predeterminado / default)"
  echo "  2) English"
  echo "=========================================="

  DEFAULT_LANG_CHOICE="1"
  if [[ "$LANG" =~ ^en ]]; then
    DEFAULT_LANG_CHOICE="2"
  fi

  if [ "$DEFAULT_LANG_CHOICE" = "2" ]; then
    read -rp "Selecciona una opción / Select an option [1-2] (default: 2 - English): " LANG_INPUT
  else
    read -rp "Selecciona una opción / Select an option [1-2] (por defecto: 1 - Español): " LANG_INPUT
  fi

  LANG_INPUT="${LANG_INPUT:-$DEFAULT_LANG_CHOICE}"

  case "$LANG_INPUT" in
    2|[eE][nN]*)
      INSTALL_LANG="en"
      ;;
    *)
      INSTALL_LANG="es"
      ;;
  esac
fi

# Helper para imprimir según el idioma elegido
echo_lang() {
  if [ "$INSTALL_LANG" = "en" ]; then
    echo "$2"
  else
    echo "$1"
  fi
}

# ==============================================================================
# DETECCIÓN AUTOMÁTICA DEL SISTEMA OPERATIVO / OS DETECTION
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

if [ "$INSTALL_LANG" = "en" ]; then
  echo "=========================================="
  echo "  🚀 Dotfiles & Environment Installer"
  echo "  🖖 Includes complete Spock AI suite"
  echo "=========================================="
  if [ -n "$DETECTED_NAME" ]; then
    echo "🔍 Detected system: $DETECTED_NAME"
  fi
  echo "Select the environment you want to install on:"
  echo "  1) macOS"
  echo "  2) CachyOS / Arch Linux"
  echo "  3) Linux (Ubuntu / Debian)"
  echo "  4) Windows 11 - WSL2"
  echo "=========================================="

  PROMPT_TEXT="Enter an option [1-4]"
  if [ -n "$DETECTED_CHOICE" ]; then
    PROMPT_TEXT="$PROMPT_TEXT (default: $DETECTED_CHOICE): "
  else
    PROMPT_TEXT="$PROMPT_TEXT: "
  fi
else
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
fi

read -rp "$PROMPT_TEXT" OS_CHOICE
OS_CHOICE="${OS_CHOICE:-$DETECTED_CHOICE}"

case "$OS_CHOICE" in
  1) TARGET_OS="macos" ;;
  2) TARGET_OS="cachyos" ;;
  3) TARGET_OS="linux" ;;
  4) TARGET_OS="wsl2" ;;
  *)
    echo_lang "❌ Opción no válida. Cancelando instalación." "❌ Invalid option. Aborting installation."
    exit 1
    ;;
esac

echo_lang "➡️ Configurando para: $TARGET_OS..." "➡️ Configuring for: $TARGET_OS..."

# ==============================================================================
# 1. INSTALACIÓN DE PAQUETES Y HERRAMIENTAS / PACKAGE INSTALLATION
# ==============================================================================
mkdir -p "$HOME/.local/bin" "$HOME/.config"

if [ "$TARGET_OS" = "macos" ]; then
  if ! xcode-select -p &>/dev/null; then
    echo_lang "📦 Instalando Xcode Command Line Tools..." "📦 Installing Xcode Command Line Tools..."
    xcode-select --install
    echo_lang "Presiona Enter cuando termine la instalación en ventana..." "Press Enter once GUI installation completes..."
    read -r
  fi

  if ! command -v brew &>/dev/null; then
    echo_lang "🍺 Instalando Homebrew..." "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -f "/opt/homebrew/bin/brew" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi

  echo_lang "📦 Instalando herramientas vía Homebrew..." "📦 Installing tools via Homebrew..."
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
  echo_lang "📦 Configurando CachyOS / Arch Linux..." "📦 Configuring CachyOS / Arch Linux..."
  
  # Determinar gestor de paquetes (paru o pacman)
  AUR_HELPER=""
  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
  elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
  fi

  echo_lang "🔄 Sincronizando repositorios e instalando paquetes base..." "🔄 Synchronizing repositories and installing base packages..."
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
    echo_lang "⚠️ Algunos paquetes fallaron en lote, instalando individualmente..." "⚠️ Some packages failed in batch, installing individually..."
    for pkg in "${ARCH_PKGS[@]}"; do
      sudo pacman -S --needed --noconfirm "$pkg" || echo_lang "⚠️ Falló $pkg, continuando..." "⚠️ Failed $pkg, continuing..."
    done
  }

  # Ollama en CachyOS / Arch
  if ! command -v ollama &>/dev/null; then
    echo_lang "🤖 Instalando Ollama..." "🤖 Installing Ollama..."
    sudo pacman -S --needed --noconfirm ollama || {
      if [ -n "$AUR_HELPER" ]; then
        $AUR_HELPER -S --needed --noconfirm ollama || true
      else
        curl -fsSL https://ollama.com/install.sh | sh || true
      fi
    }
  fi

elif [ "$TARGET_OS" = "linux" ] || [ "$TARGET_OS" = "wsl2" ]; then
  echo_lang "📦 Actualizando apt e instalando herramientas base..." "📦 Updating apt and installing base packages..."
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
    echo_lang "⭐ Instalando Starship..." "⭐ Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi

  # Atuin
  if ! command -v atuin &>/dev/null; then
    echo_lang "📜 Instalando Atuin..." "📜 Installing Atuin..."
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash
  fi

  # Zoxide
  if ! command -v zoxide &>/dev/null; then
    echo_lang "📂 Instalando Zoxide..." "📂 Installing Zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  fi

  # eza
  if ! command -v eza &>/dev/null; then
    echo_lang "📁 Instalando eza..." "📁 Installing eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg || true
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo apt update && sudo apt install -y eza || true
  fi

  sudo apt install -y zsh-autosuggestions zsh-syntax-highlighting || true

  # Ollama
  if ! command -v ollama &>/dev/null; then
    echo_lang "🤖 Instalando Ollama..." "🤖 Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh || true
  fi
fi

# ==============================================================================
# 2. CONFIGURACIÓN E INSTALACIÓN DEL SISTEMA SPOCK AI / SPOCK AI CONFIGURATION
# ==============================================================================
echo ""
echo "=========================================="
echo_lang "  🖖 Configurando Sistema Spock AI" "  🖖 Configuring Spock AI System"
echo "=========================================="

# Permisos ejecutables para el script de Spock
chmod +x "$DOTFILES_DIR/zsh/spock.py"

# Enlace directo en ~/.local/bin/spock para ejecución global
ln -sf "$DOTFILES_DIR/zsh/spock.py" "$HOME/.local/bin/spock"
echo_lang "✅ Enlace ejecutable creado: $HOME/.local/bin/spock" "✅ Executable link created: $HOME/.local/bin/spock"

# Configuración persistente e idioma de Spock
mkdir -p "$SPOCK_CONFIG_DIR"
CONFIG_FILE="$SPOCK_CONFIG_DIR/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  if [ "$INSTALL_LANG" = "en" ]; then
    echo '{"lang": "en"}' > "$CONFIG_FILE"
    echo "✅ Spock configured in English (~/.config/spock/config.json)."
  else
    echo '{"lang": "es"}' > "$CONFIG_FILE"
    echo "✅ Spock configurado en idioma Español (~/.config/spock/config.json)."
  fi
else
  echo_lang "ℹ️ Configuración existente de Spock detectada en $CONFIG_FILE." "ℹ️ Existing Spock configuration detected at $CONFIG_FILE."
fi

# Iniciar o verificar el servicio Ollama
echo_lang "🔌 Verificando servicio de Ollama..." "🔌 Checking Ollama service..."
if ! curl -s http://localhost:11434/api/tags &>/dev/null; then
  echo_lang "⚡ Iniciando Ollama en segundo plano..." "⚡ Starting Ollama in background..."
  if [ "$TARGET_OS" = "macos" ]; then
    brew services start ollama 2>/dev/null || nohup ollama serve >/dev/null 2>&1 &
  else
    sudo systemctl enable --now ollama 2>/dev/null || nohup ollama serve >/dev/null 2>&1 &
  fi

  echo_lang "⏳ Esperando respuesta del motor Ollama..." "⏳ Waiting for Ollama engine response..."
  OLLAMA_UP=0
  for i in {1..20}; do
    if curl -s http://localhost:11434/api/tags &>/dev/null; then
      OLLAMA_UP=1
      break
    fi
    sleep 1
  done

  if [ $OLLAMA_UP -eq 1 ]; then
    echo_lang "✅ Ollama está listo y respondiendo." "✅ Ollama is ready and responding."
  else
    echo_lang "⚠️ Ollama no respondió a tiempo. Puedes iniciarlo manualmente con 'ollama serve'." "⚠️ Ollama did not respond in time. You can start it manually with 'ollama serve'."
  fi
else
  echo_lang "✅ Servicio Ollama ya se encuentra activo." "✅ Ollama service is already active."
fi

# Descarga y verificación del modelo de IA para Spock
if command -v ollama &>/dev/null; then
  echo_lang "🧠 Verificando modelo de IA de Spock ($SPOCK_MODEL)..." "🧠 Checking Spock AI model ($SPOCK_MODEL)..."
  if ollama list 2>/dev/null | grep -q "$SPOCK_MODEL"; then
    echo_lang "✅ Modelo $SPOCK_MODEL ya disponible en Ollama." "✅ Model $SPOCK_MODEL already available in Ollama."
  else
    echo_lang "📥 Descargando modelo $SPOCK_MODEL para Spock (esto puede tardar unos minutos según tu conexión)..." "📥 Downloading $SPOCK_MODEL model for Spock (this may take a few minutes depending on your connection)..."
    ollama pull "$SPOCK_MODEL" || {
      echo_lang "⚠️ No se pudo completar la descarga automática. Ejecuta 'ollama pull $SPOCK_MODEL' cuando tengas conexión." "⚠️ Automatic download could not be completed. Run 'ollama pull $SPOCK_MODEL' when connected."
    }
  fi
fi

# ==============================================================================
# 3. VINCULAR DOTFILES (SYMLINKS) / LINK DOTFILES
# ==============================================================================
echo ""
echo_lang "🔗 Creando enlaces simbólicos de Dotfiles..." "🔗 Creating Dotfiles symlinks..."
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
    echo_lang "🪟 Configurando enlace automático para WezTerm en Windows ($WIN_HOME)..." "🪟 Configuring automatic link for WezTerm in Windows ($WIN_HOME)..."
    cat << EOF > "$WIN_HOME/.wezterm.lua"
return dofile([[\\\\wsl.localhost\\$DISTRO\\home\\$USER\\dotfiles\\wezterm\\.wezterm.lua]])
EOF
    echo_lang "✅ Archivo .wezterm.lua generado en Windows vinculado a WSL2." "✅ .wezterm.lua file generated in Windows linked to WSL2."
  else
    echo_lang "⚠️ No se pudo ubicar $WIN_HOME. Configura el archivo puente en Windows manualmente." "⚠️ Could not locate $WIN_HOME. Please configure bridge file in Windows manually."
  fi
fi

# ==============================================================================
# 4. FINALIZAR Y COMPILAR / FINALIZE & COMPILE
# ==============================================================================
if command -v zcompile &>/dev/null; then
  zcompile ~/.zshrc || true
fi

echo ""
if [ "$INSTALL_LANG" = "en" ]; then
  echo "============================================================"
  echo "  🎉 Installation complete for $TARGET_OS!"
  echo "  🖖 Spock system is 100% operational."
  echo "============================================================"
  echo "Available Spock commands and features:"
  echo "  • spock                    -> Open interactive chat session"
  echo "  • spock \"<query>\"          -> Suggest commands or answer questions"
  echo "  • ask \"<query>\"            -> Suggest commands and run them interactively"
  echo "  • fix  (or Ctrl + G)       -> Diagnose and fix the last command error"
  echo "  • spock explain <file>     -> Explain code architecture and logic"
  echo "  • spock debug <error>      -> Deduce root cause and anomalies"
  echo "  • spock lang [es|en]       -> Change language anytime"
  echo "============================================================"
  echo "Run 'exec zsh' or restart your terminal to begin."
else
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
fi
