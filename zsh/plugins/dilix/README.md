# 🤖 Dilix Zsh Plugin

Plugin oficial de Zsh para **Dilix**: Asistente lógico de terminal, copiloto de desarrollo y diagnóstico de comandos impulsado por IA local (Ollama).

Totalmente optimizado y con soporte de primer nivel para:
- 🍎 **macOS** (Apple Silicon & Intel, Homebrew)
- 🐧 **CachyOS** & Arch Linux (Pacman, Paru, Yay, kernels optimizados)
- 🐧 **Ubuntu** & Debian (APT, PPAs)
- 🪟 **WSL2** (Windows Subsystem for Linux, interoperabilidad con Windows)

---

## 🚀 Instalación y Carga

### Opción 1: En tus Dotfiles (Predeterminada)
En tu archivo `~/.zshrc`:
```zsh
fpath=("$HOME/dotfiles/zsh/plugins/dilix" $fpath)
source "$HOME/dotfiles/zsh/plugins/dilix/dilix.plugin.zsh"
```

### Opción 2: Con Oh-My-Zsh
Clona o enlaza el repositorio en tu carpeta de plugins personalizados:
```bash
ln -s "$HOME/dotfiles/zsh/plugins/dilix" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/dilix"
```
Y añade `dilix` a tu lista de plugins en `~/.zshrc`:
```zsh
plugins=(... dilix)
```

### Opción 3: Con Zinit
```zsh
zinit light "$HOME/dotfiles/zsh/plugins/dilix"
```

---

## ⚡ Comandos Disponibles

| Comando | Descripción |
| :--- | :--- |
| `dilix menu` | Menú interactivo con todas las opciones disponibles |
| `dilix` | Abre canal de chat interactivo con memoria (o repara error previo) |
| `dilix chat` | Inicia canal de conversación continuo con Dilix |
| `ask "<consulta>"` | Sugiere comandos de terminal a partir de lenguaje natural |
| `fix` / `Ctrl+G` | Diagnostica la causa raíz y repara el último comando que falló |
| `dilix explain <archivo>` | Explica la arquitectura y lógica del código seleccionado |
| `dilix debug <archivo/error>`| Analiza trazas de error y deduce el origen de la anomalía |
| `dilix lang [es\|en]` | Cambia o consulta el idioma activo (Español / Inglés) |
| `dilix model` | Consulta el modelo activo y el estado del servicio Ollama |
| `dilix help` | Lista completa de comandos y ayuda |

---

## ⚙️ Variables de Entorno

```zsh
export DILIX_MODEL="qwen2.5-coder:1.5b"  # Modelo de Ollama a utilizar
export DILIX_AUTO_MODE="ask"            # Modo ante fallos: "ask", "auto" o "hint"
export DILIX_LANG="es"                  # Idioma forzado: "es" o "en" (o vía config.json)
```
