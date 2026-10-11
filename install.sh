#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  🚀 Instalador de Dotfiles & Entorno"
echo "=========================================="
echo "Selecciona el entorno en el que estás ejecutando:"
echo "  1) macOS"
echo "  2) Linux (Ubuntu / Debian)"
echo "  3) Windows 11 - WSL2 (Ubuntu / Debian)"
echo "=========================================="
read -rp "Ingresa una opción [1-3]: " OS_CHOICE

case "$OS_CHOICE" in
  1)
    TARGET_OS="macos"
    ;;
  2)
    TARGET_OS="linux"
    ;;
  3)
    TARGET_OS="wsl2"
    ;;
  *)
    echo "❌ Opción no válida. Cancelando instalación."
    exit 1
    ;;
esac

echo "➡️ Configurando para: $TARGET_OS..."

# ==============================================================================
# 1. INSTALACIÓN DE PAQUETES
# ==============================================================================
if [ "$TARGET_OS" = "macos" ]; then
  # Xcode Tools
  if ! xcode-select -p &>/dev/null; then
    echo "📦 Instalando Xcode Command Line Tools..."
    xcode-select --install
    echo "Presiona Enter cuando termine la instalación en ventana..."
    read -r
  fi

  # Homebrew
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
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zoxide \
    fzf \
    eza \
    bat \
    gh

  brew install --cask font-jetbrains-mono-nerd-font || true

elif [ "$TARGET_OS" = "linux" ] || [ "$TARGET_OS" = "wsl2" ]; then
  echo "📦 Actualizando apt e instalando herramientas base..."
  sudo apt update && sudo apt install -y \
    zsh \
    curl \
    git \
    fzf \
    bat \
    build-essential

  # En Debian/Ubuntu bat se instala como 'batcat'
  mkdir -p ~/.local/bin
  ln -sf /usr/bin/batcat ~/.local/bin/bat || true

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

  # Plugins de Zsh para Ubuntu/Debian
  sudo apt install -y zsh-autosuggestions zsh-syntax-highlighting || true

  # Ollama en Linux/WSL2
  if ! command -v ollama &>/dev/null; then
    echo "🤖 Instalando Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh || true
  fi

  # En WSL2 WezTerm corre en Windows nativo, no dentro de WSL
  if [ "$TARGET_OS" = "wsl2" ]; then
    echo "💡 Nota: En WSL2 la interfaz de WezTerm debe instalarse en Windows 11."
  fi
fi

# ==============================================================================
# 2. VINCULAR DOTFILES (SYMLINKS)
# ==============================================================================
echo "🔗 Creando enlaces simbólicos..."
rm -f ~/.zshrc ~/.wezterm.lua

ln -sf "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc

# Si es macOS o Linux nativo con interfaz, enlaza wezterm
if [ "$TARGET_OS" != "wsl2" ]; then
  ln -sf "$DOTFILES_DIR/wezterm/.wezterm.lua" ~/.wezterm.lua
fi

# ==============================================================================
# 3. FINALIZAR Y COMPILAR
# ==============================================================================
if command -v zcompile &>/dev/null; then
  zcompile ~/.zshrc || true
fi

echo "✅ Entorno $TARGET_OS configurado exitosamente. Ejecuta 'exec zsh' para comenzar."

