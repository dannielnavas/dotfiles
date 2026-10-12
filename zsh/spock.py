#!/usr/bin/env python3
"""
Spock - Asistente Lógico de Terminal y Copiloto de Programación para Zsh.
Soporte Bilingüe: Español (es) & Inglés (en).
Configuración persistente en ~/.config/spock/config.json.
"""

import sys
import os
import re
import json
import urllib.request
import urllib.error
import subprocess
import platform

try:
    import readline
except ImportError:
    pass

# ==============================================================================
# CONFIGURACIÓN Y CONSTANTES
# ==============================================================================
DEFAULT_MODEL = os.environ.get("SPOCK_MODEL", os.environ.get("WARP_AI_MODEL", "qwen2.5-coder:1.5b"))
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")

CONFIG_DIR = os.path.expanduser("~/.config/spock")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")

# Códigos de Color ANSI
CYAN = "\033[36m"
MAGENTA = "\033[35m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
BLUE = "\033[34m"
BOLD = "\033[1m"
DIM = "\033[2m"
ITALIC = "\033[3m"
RESET = "\033[0m"

# ==============================================================================
# INTERNACIONALIZACIÓN (I18N) - ESPAÑOL & INGLÉS
# ==============================================================================
TEXTS = {
    "es": {
        "persona": (
            "Eres el Oficial Científico Spock de la USS Enterprise, adaptado como copiloto de terminal e ingeniero de software en Mac/Linux.\n"
            "Directrices:\n"
            "- Eres supremamente lógico, analítico, cortés, sereno y perspicaz.\n"
            "- Utilizas expresiones vulcanas como: 'Fascinante.', 'Lógicamente...', 'Desde una perspectiva puramente racional...', 'Es altamente probable que...', 'El curso de acción óptimo es...'.\n"
            "- Responde SIEMPRE en ESPAÑOL de forma fluida, natural, concisa y elegante.\n"
            "- Vas directo a la raíz del problema con rigor técnico y claridad didáctica.\n"
        ),
        "box_explain": "Análisis Lógico de Código: {source}",
        "box_debug": "Depuración Lógica y Causa Raíz",
        "box_fix": "Diagnóstico y Solución de Error",
        "box_ask": "Sugerencia de Comando",
        "box_chat": "Canal de Comunicación Directo",
        "box_query": "Análisis Lógico",
        "chat_welcome_1": "Oficial Científico Spock a su servicio.",
        "chat_welcome_2": "Puedo explicar código, depurar errores y analizar lógica de sistemas.",
        "chat_welcome_3": "Escribe 'q' o 'exit' para salir, 'clear' para limpiar pantalla.",
        "chat_farewell": "Larga vida y prosperidad.",
        "chat_session_ended": "Larga vida y prosperidad. Sesión finalizada.",
        "menu_action": "Acción:",
        "menu_exec": "Ejecutar",
        "menu_prompt": "En el prompt",
        "menu_copy": "Copiar",
        "menu_quit": "Salir:",
        "copied_ok": "✔ Copiado al portapapeles con éxito.",
        "copied_err": "⚠️ No se pudo copiar al portapapeles.",
        "failed_label": "Falló:",
        "cause_label": "Causa lógica:",
        "action_label": "Qué toca hacer:",
        "solution_label": "Solución sugerida:",
        "query_label": "Consulta:",
        "explanation_label": "Explicación:",
        "suggested_label": "Comando sugerido:",
        "ollama_offline": "Ollama no responde en {host}. Inícialo con 'ollama serve' o abre la aplicación.",
        "no_error_found": "💡 No hay ningún comando previo registrado para analizar.",
        "no_code_found": "💡 No se detectó código ni contenido para analizar.",
        "no_debug_target": "💡 No se proporcionó ningún mensaje o traza de error para depurar.",
        "stdin_label": "Entrada estándar (stdin)",
        "snippet_label": "Fragmento / Comando",
        "processing_explain": "Procesando estructura y deduciendo funcionamiento con {model}...",
        "processing_debug": "Aislando variables y deduciendo el origen de la anomalía...",
        "processing_fix": "Examinando la anomalía con {model}...",
        "processing_ask": "Consultando {model}...",
    },
    "en": {
        "persona": (
            "You are Science Officer Spock of the USS Enterprise, serving as a logical terminal copilot and software engineer on Mac/Linux.\n"
            "Guidelines:\n"
            "- You are supremely logical, analytical, courteous, composed, and perceptive.\n"
            "- Use subtle Vulcan phrasing such as: 'Fascinating.', 'Logically...', 'From a purely rational perspective...', 'It is highly probable that...', 'The optimal course of action is...'.\n"
            "- ALWAYS respond in ENGLISH in a fluent, natural, concise, and articulate manner.\n"
            "- Address the root cause directly with technical rigor and didactic clarity.\n"
        ),
        "box_explain": "Logical Code Analysis: {source}",
        "box_debug": "Logical Debugging & Root Cause Analysis",
        "box_fix": "Error Diagnosis & Solution",
        "box_ask": "Command Suggestion",
        "box_chat": "Direct Communication Channel",
        "box_query": "Logical Analysis",
        "chat_welcome_1": "Science Officer Spock at your service.",
        "chat_welcome_2": "I can explain code, debug errors, and analyze system logic.",
        "chat_welcome_3": "Type 'q' or 'exit' to quit, 'clear' to clear screen.",
        "chat_farewell": "Live long and prosper.",
        "chat_session_ended": "Live long and prosper. Session ended.",
        "menu_action": "Action:",
        "menu_exec": "Execute",
        "menu_prompt": "In prompt",
        "menu_copy": "Copy",
        "menu_quit": "Quit:",
        "copied_ok": "✔ Copied to clipboard successfully.",
        "copied_err": "⚠️ Could not copy to clipboard.",
        "failed_label": "Failed:",
        "cause_label": "Logical cause:",
        "action_label": "Recommended action:",
        "solution_label": "Suggested solution:",
        "query_label": "Query:",
        "explanation_label": "Explanation:",
        "suggested_label": "Suggested command:",
        "ollama_offline": "Ollama is not responding at {host}. Start it with 'ollama serve' or open the app.",
        "no_error_found": "💡 No recent command registered to analyze.",
        "no_code_found": "💡 No code or content detected to analyze.",
        "no_debug_target": "💡 No error message or trace provided to debug.",
        "stdin_label": "Standard input (stdin)",
        "snippet_label": "Snippet / Command",
        "processing_explain": "Processing structure and deducing mechanics with {model}...",
        "processing_debug": "Isolating variables and deducing the root cause...",
        "processing_fix": "Examining anomaly with {model}...",
        "processing_ask": "Querying {model}...",
    }
}

# ==============================================================================
# GESTIÓN DE CONFIGURACIÓN Y PERSISTENCIA DE IDIOMA
# ==============================================================================
def load_config() -> dict:
    if os.path.isfile(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def save_config(cfg: dict):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(CONFIG_FILE, "w") as f:
            json.dump(cfg, f, indent=2)
    except Exception as e:
        print_tty(f"{YELLOW}⚠️ No se pudo guardar configuración: {e}{RESET}")

def get_current_language() -> str:
    """Obtiene el idioma activo: prioridad variable de entorno SPOCK_LANG > config.json."""
    env_lang = os.environ.get("SPOCK_LANG", "").lower().strip()
    if env_lang in ("es", "en"):
        return env_lang
    cfg = load_config()
    cfg_lang = cfg.get("lang", "").lower().strip()
    if cfg_lang in ("es", "en"):
        return cfg_lang
    return ""

def ensure_language() -> str:
    """Si no hay idioma configurado, pide al usuario seleccionarlo por primera vez y lo guarda."""
    lang = get_current_language()
    if lang:
        return lang

    # Menú de selección inicial
    print_tty()
    print_tty(f"{CYAN}╭─ {BOLD}{MAGENTA}🖖 Spock{RESET} {CYAN}• {BOLD}Configuración de Idioma / Language Setup{RESET} {CYAN}" + "─" * 15 + f"{RESET}")
    print_tty(f"{CYAN}│{RESET} Por favor seleccione su idioma preferido:")
    print_tty(f"{CYAN}│{RESET} Please select your preferred language:")
    print_tty(f"{CYAN}│{RESET}   {GREEN}[1]{RESET} Español  (Spanish)")
    print_tty(f"{CYAN}│{RESET}   {GREEN}[2]{RESET} English  (Inglés)")
    print_tty(f"{CYAN}╰" + "─" * 60 + f"{RESET}")
    print_tty(f" {BOLD}Opción / Choice [1/2]:{RESET} ", end="")
    
    choice = read_key().strip()
    print_tty()

    selected = "en" if choice in ("2", "en", "e", "E") else "es"
    cfg = load_config()
    cfg["lang"] = selected
    save_config(cfg)

    if selected == "en":
        print_tty(f" {GREEN}✔ Language configured to English.{RESET} Saved as default in ~/.config/spock/config.json\n")
    else:
        print_tty(f" {GREEN}✔ Idioma configurado a Español.{RESET} Guardado como predeterminado en ~/.config/spock/config.json\n")
    return selected

def t(key: str, **kwargs) -> str:
    """Obtiene una cadena de texto localizada según el idioma actual."""
    lang = ensure_language()
    bundle = TEXTS.get(lang, TEXTS["es"])
    template = bundle.get(key, TEXTS["es"].get(key, key))
    if kwargs:
        return template.format(**kwargs)
    return template

# ==============================================================================
# UTILIDADES DE TERMINAL Y E/S
# ==============================================================================
def print_tty(msg="", end="\n"):
    try:
        with open("/dev/tty", "w") as tty:
            tty.write(msg + end)
            tty.flush()
    except Exception:
        sys.stderr.write(msg + end)
        sys.stderr.flush()

def read_key():
    if not sys.stdin.isatty():
        try:
            ch = sys.stdin.read(1)
            return ch if ch else "q"
        except Exception:
            return "q"

    try:
        with open("/dev/tty", "r") as tty:
            import tty as tty_module
            import termios
            fd = tty.fileno()
            old_settings = termios.tcgetattr(fd)
            try:
                tty_module.setraw(fd)
                ch = tty.read(1)
                if ch == "\x1b":
                    import select
                    r, _, _ = select.select([tty], [], [], 0.05)
                    if r:
                        tty.read(2)
                        return "ESC"
                    return "q"
                return ch
            finally:
                termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    except Exception:
        try:
            line = input()
            return line.strip()[:1] if line.strip() else "\r"
        except Exception:
            return "q"

def clean_command(cmd: str) -> str:
    cmd = cmd.strip()
    if cmd.startswith("```"):
        lines = cmd.splitlines()
        if len(lines) >= 2 and lines[-1].startswith("```"):
            cmd = "\n".join(lines[1:-1]).strip()
        else:
            cmd = re.sub(r"^```[a-zA-Z]*\n?", "", cmd).rstrip("`").strip()
    if cmd.startswith("`") and cmd.endswith("`") and len(cmd) > 1:
        cmd = cmd[1:-1].strip()
    return cmd

def copy_to_clipboard(text: str) -> bool:
    system = platform.system().lower()
    try:
        if system == "darwin":
            p = subprocess.Popen(["pbcopy"], stdin=subprocess.PIPE)
            p.communicate(text.encode("utf-8"))
            return p.returncode == 0
        elif "microsoft" in platform.uname().release.lower() or os.path.exists("/mnt/c/Windows"):
            p = subprocess.Popen(["clip.exe"], stdin=subprocess.PIPE)
            p.communicate(text.encode("utf-8"))
            return p.returncode == 0
        else:
            if subprocess.run(["which", "wl-copy"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
                p = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE)
                p.communicate(text.encode("utf-8"))
                return p.returncode == 0
            elif subprocess.run(["which", "xclip"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
                p = subprocess.Popen(["xclip", "-selection", "clipboard"], stdin=subprocess.PIPE)
                p.communicate(text.encode("utf-8"))
                return p.returncode == 0
    except Exception:
        pass
    return False

def check_ollama():
    try:
        req = urllib.request.Request(f"{OLLAMA_HOST}/api/tags", headers={"User-Agent": "Spock/1.0"})
        with urllib.request.urlopen(req, timeout=1.5) as resp:
            return resp.status == 200
    except Exception:
        return False

def get_terminal_scrollback(lines=30):
    try:
        res = subprocess.run(
            ["wezterm", "cli", "get-text", "--start-line", f"-{lines}"],
            capture_output=True, text=True, timeout=1
        )
        if res.returncode == 0 and res.stdout.strip():
            raw_lines = [l.strip() for l in res.stdout.splitlines() if l.strip()]
            return "\n".join(raw_lines[-18:])
    except Exception:
        pass
    return ""

def render_box(title: str, content_lines: list):
    print_tty()
    print_tty(f"{CYAN}╭─ {BOLD}{MAGENTA}🖖 Spock{RESET} {CYAN}• {BOLD}{title}{RESET} {CYAN}" + "─" * 42 + f"{RESET}")
    for line in content_lines:
        print_tty(f"{CYAN}│{RESET} {line}")
    print_tty(f"{CYAN}╰" + "─" * (55) + f"{RESET}")

def interactive_menu(command: str):
    while True:
        menu_text = (
            f" {BOLD}{t('menu_action')}{RESET} "
            f"[{GREEN}↵ Enter{RESET}/{GREEN}e{RESET}] {t('menu_exec')}  "
            f"[{YELLOW}m{RESET}] {t('menu_prompt')}  "
            f"[{CYAN}c{RESET}] {t('menu_copy')}  "
            f"[{DIM}q{RESET}] {t('menu_quit')} "
        )
        print_tty(menu_text, end="")
        key = read_key()
        print_tty()

        if key in ("\r", "\n", "e", "E"):
            sys.stdout.write(f"EXEC:{command}\n")
            sys.stdout.flush()
            break
        elif key in ("m", "M"):
            sys.stdout.write(f"MODIFY:{command}\n")
            sys.stdout.flush()
            break
        elif key in ("c", "C"):
            if copy_to_clipboard(command):
                print_tty(f" {GREEN}{t('copied_ok')}{RESET}")
            else:
                print_tty(f" {YELLOW}{t('copied_err')}{RESET}")
        elif key in ("q", "Q", "\x03", "\x1b", "ESC"):
            sys.stdout.write("CANCEL:\n")
            sys.stdout.flush()
            break

# ==============================================================================
# CLIENTE OLLAMA
# ==============================================================================
def query_ollama_json(prompt: str) -> dict:
    if not check_ollama():
        return {
            "error": "OLLAMA_OFFLINE",
            "message": t("ollama_offline", host=OLLAMA_HOST)
        }

    payload = {
        "model": DEFAULT_MODEL,
        "prompt": prompt,
        "stream": False,
        "format": "json",
        "options": {"temperature": 0.15}
    }

    try:
        req = urllib.request.Request(
            f"{OLLAMA_HOST}/api/generate",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=25) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            raw_text = data.get("response", "").strip()
            try:
                return json.loads(raw_text)
            except Exception:
                match = re.search(r"\{.*\}", raw_text, re.DOTALL)
                if match:
                    return json.loads(match.group(0))
            return {"raw": raw_text}
    except Exception as e:
        return {"error": "API_ERROR", "message": str(e)}

def stream_ollama_text(prompt: str, context: list = None) -> (str, list):
    if not check_ollama():
        print_tty(f"{RED}❌ Error: {t('ollama_offline', host=OLLAMA_HOST)}{RESET}")
        return "", context

    payload = {
        "model": DEFAULT_MODEL,
        "prompt": prompt,
        "stream": True,
        "options": {"temperature": 0.3}
    }
    if context:
        payload["context"] = context

    full_response = []
    final_context = context

    try:
        req = urllib.request.Request(
            f"{OLLAMA_HOST}/api/generate",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            for line in resp:
                if line:
                    data = json.loads(line.decode("utf-8"))
                    chunk = data.get("response", "")
                    print_tty(chunk, end="")
                    full_response.append(chunk)
                    if data.get("done") and "context" in data:
                        final_context = data["context"]
        print_tty()
        return "".join(full_response), final_context
    except Exception as e:
        print_tty(f"\n{RED}❌ Error: {e}{RESET}")
        return "".join(full_response), final_context

# ==============================================================================
# COMANDO: GESTIÓN DE IDIOMA (SPOCK LANG)
# ==============================================================================
def handle_lang(args: list):
    cfg = load_config()
    current = get_current_language() or "es"

    if args:
        target = args[0].lower().strip()
        if target in ("es", "spanish", "español"):
            cfg["lang"] = "es"
            save_config(cfg)
            print_tty(f"{GREEN}✔ Idioma configurado a Español.{RESET} Spock responderá en español por defecto.")
            return
        elif target in ("en", "english", "inglés", "ingles"):
            cfg["lang"] = "en"
            save_config(cfg)
            print_tty(f"{GREEN}✔ Language configured to English.{RESET} Spock will respond in English by default.")
            return
        else:
            print_tty(f"{YELLOW}Opción no reconocida / Unrecognized option: '{target}'. Use 'es' o 'en'.{RESET}")
            return

    # Si se invoca sin argumentos: muestra el estado actual y menú
    print_tty()
    print_tty(f"{CYAN}╭─ {BOLD}{MAGENTA}🖖 Spock{RESET} {CYAN}• {BOLD}Idioma / Language Settings{RESET} {CYAN}" + "─" * 25 + f"{RESET}")
    print_tty(f"{CYAN}│{RESET} Idioma actual / Current language: {GREEN}{BOLD}{'English' if current == 'en' else 'Español'}{RESET}")
    print_tty(f"{CYAN}│{RESET} Selecciona una opción para cambiar / Select to change:")
    print_tty(f"{CYAN}│{RESET}   {CYAN}[1]{RESET} Español  (Spanish)")
    print_tty(f"{CYAN}│{RESET}   {CYAN}[2]{RESET} English  (Inglés)")
    print_tty(f"{CYAN}╰" + "─" * 55 + f"{RESET}")
    print_tty(f" {BOLD}Opción / Choice [1/2]:{RESET} ", end="")
    choice = read_key().strip()
    print_tty()

    if choice in ("1", "es"):
        cfg["lang"] = "es"
        save_config(cfg)
        print_tty(f"{GREEN}✔ Idioma establecido a Español.{RESET}")
    elif choice in ("2", "en"):
        cfg["lang"] = "en"
        save_config(cfg)
        print_tty(f"{GREEN}✔ Language set to English.{RESET}")
    else:
        print_tty(f"{DIM}Sin cambios / No changes made.{RESET}")

# ==============================================================================
# FUNCIONALIDADES PRINCIPALES
# ==============================================================================
def handle_explain(args: list):
    lang = ensure_language()
    code_content = ""
    source_label = ""

    if not sys.stdin.isatty():
        code_content = sys.stdin.read().strip()
        source_label = t("stdin_label")
    elif args and os.path.isfile(args[0]):
        filepath = args[0]
        try:
            with open(filepath, "r", errors="ignore") as f:
                lines = f.readlines()
            if len(lines) > 400:
                code_content = "".join(lines[:400])
                source_label = f"{filepath} (head 400 lines)"
            else:
                code_content = "".join(lines)
                source_label = filepath
        except Exception as e:
            print_tty(f"{RED}❌ {e}{RESET}")
            return
    elif args:
        code_content = " ".join(args).strip()
        source_label = t("snippet_label")
    else:
        print_tty(f"{YELLOW}Usage / Uso:{RESET} spock explain <file | 'cmd' | pipe>")
        return

    if not code_content:
        print_tty(f"{YELLOW}{t('no_code_found')}{RESET}")
        return

    print_tty()
    print_tty(f"{CYAN}╭─ {BOLD}{MAGENTA}🖖 Spock{RESET} {CYAN}• {BOLD}{t('box_explain', source=source_label)}{RESET} {CYAN}" + "─" * 20 + f"{RESET}")
    print_tty(f"{DIM}{t('processing_explain', model=DEFAULT_MODEL)}{RESET}\n")

    if lang == "en":
        prompt = f"""{t('persona')}
Dissect and explain the following code or command with rigorous logical precision.
Source: {source_label}

```
{code_content}
```

Structure your response:
1. **General Logical Purpose**: (1-2 concise sentences on what it achieves).
2. **Execution Flow & Mechanics**: (step-by-step breakdown of internal mechanics).
3. **Critical Evaluation**: (algorithmic efficiency, edge cases, vulnerabilities, or improvements).

Maintain your composed, sharp Vulcan demeanor."""
    else:
        prompt = f"""{t('persona')}
Disecciona y explica el siguiente código o comando con rigor analítico.
Origen: {source_label}

```
{code_content}
```

Estructura tu respuesta exactamente así:
1. **Propósito Lógico General**: (1 o 2 oraciones concisas de qué hace).
2. **Flujo de Ejecución y Mecánica Interna**: (desglose paso a paso de los componentes clave).
3. **Evaluación Crítica**: (eficiencia algorítmica, casos borde, vulnerabilidades o mejoras si las hay).

Mantén tu tono vulcaniano: sobrio, impecable y directo al grano."""

    stream_ollama_text(prompt)
    print_tty(f"{CYAN}╰" + "─" * 65 + f"{RESET}\n")

def handle_debug(args: list):
    lang = ensure_language()
    error_content = ""
    source = ""

    if not sys.stdin.isatty():
        error_content = sys.stdin.read().strip()
        source = t("stdin_label")
    elif args and os.path.isfile(args[0]):
        try:
            with open(args[0], "r", errors="ignore") as f:
                error_content = f.read()[-3000:]
            source = args[0]
        except Exception as e:
            print_tty(f"{RED}❌ {e}{RESET}")
            return
    elif args:
        error_content = " ".join(args).strip()
        source = t("snippet_label")
    else:
        error_content = get_terminal_scrollback(30)
        source = "Terminal scrollback"

    if not error_content:
        print_tty(f"{YELLOW}{t('no_debug_target')}{RESET}")
        return

    print_tty()
    print_tty(f"{CYAN}╭─ {BOLD}{MAGENTA}🖖 Spock{RESET} {CYAN}• {BOLD}{t('box_debug')}{RESET} {CYAN}" + "─" * 30 + f"{RESET}")
    print_tty(f"{DIM}{t('processing_debug')}{RESET}\n")

    if lang == "en":
        prompt = f"""{t('persona')}
Debug the following system anomaly, error trace, or code failure ({source}):
```
{error_content}
```

Structure your response:
1. **Root Cause**: (Exact deduction of what failed logically and why).
2. **Logical Analysis**: (Concise explanation of the failure mechanism).
3. **Remediation Procedure**: (Exact step-by-step fix and corrected code/command).

Be analytical, precise, and direct."""
    else:
        prompt = f"""{t('persona')}
El usuario solicita depuración de una anomalía o error en su sistema/código ({source}):
```
{error_content}
```

Estructura tu respuesta:
1. **Causa Raíz (Root Cause)**: (Diagnóstico exacto de qué falló y por qué ocurrió lógicamente).
2. **Deducción y Análisis**: (Explicación concisa del mecanismo de fallo).
3. **Procedimiento de Solución**: (Instrucciones exactas y código o comando corregido).

Sé analítico, preciso y no uses rodeos."""

    stream_ollama_text(prompt)
    print_tty(f"{CYAN}╰" + "─" * 65 + f"{RESET}\n")

def handle_fix(last_cmd: str, last_code: str, error_msg: str = ""):
    lang = ensure_language()
    if not last_cmd.strip():
        print_tty(f"{YELLOW}{t('no_error_found')}{RESET}")
        sys.stdout.write("CANCEL:\n")
        return

    scrollback = error_msg if error_msg else get_terminal_scrollback(25)
    print_tty(f"{DIM}🖖 Spock {t('processing_fix', model=DEFAULT_MODEL)}{RESET}")

    if lang == "en":
        prompt = f"""{t('persona')}
The following terminal command just failed:
Command executed: {last_cmd}
Exit code: {last_code}
Current directory: {os.getcwd()}
Terminal output context:
{scrollback}

Analyze the logical cause of failure and formulate the exact correction.
Respond ONLY in this valid JSON format:
{{
  "causa": "Direct 1-sentence logical explanation of why it failed in English.",
  "que_hacer": "Clear, concise instruction of what to do in English.",
  "comando": "Exact corrected executable terminal command, no markdown, no quotes"
}}"""
    else:
        prompt = f"""{t('persona')}
El siguiente comando de terminal acaba de fallar:
Comando ejecutado: {last_cmd}
Código de salida (exit code): {last_code}
Directorio actual: {os.getcwd()}
Contexto / Salida de terminal:
{scrollback}

Analiza la causa lógica del fallo y formula la corrección exacta.
Responde ÚNICAMENTE en este formato JSON válido:
{{
  "causa": "Explicación directa de 1 frase del por qué falló de manera lógica en español.",
  "que_hacer": "Instrucción clara y concisa de qué toca hacer en español.",
  "comando": "Comando exacto de terminal corregido para solucionar o reintentar, sin markdown ni explicaciones adicionales"
}}"""

    result = query_ollama_json(prompt)
    if "error" in result:
        print_tty(f"{RED}❌ Error: {result.get('message')}{RESET}")
        sys.stdout.write("CANCEL:\n")
        return

    causa = result.get("causa", "The command returned an unexpected error code.")
    que_hacer = result.get("que_hacer", "Verify command syntax or dependencies.")
    comando = clean_command(result.get("comando", ""))

    lines = [
        f"{BOLD}{RED}❌ {t('failed_label')}{RESET} {CYAN}{last_cmd}{RESET} {DIM}(exit code: {last_code}){RESET}",
        f"{BOLD}🔍 {t('cause_label')}{RESET} {causa}",
        f"{BOLD}💡 {t('action_label')}{RESET} {que_hacer}",
    ]
    if comando:
        lines.append(f"{BOLD}⚡ {t('solution_label')}{RESET}")
        lines.append(f"  {GREEN}{BOLD}{comando}{RESET}")

    render_box(t("box_fix"), lines)

    if comando:
        interactive_menu(comando)
    else:
        sys.stdout.write("CANCEL:\n")

def handle_ask(query: str):
    lang = ensure_language()
    if not query.strip():
        print_tty(f"{YELLOW}Usage: ask \"query\" / Uso: ask \"consulta\"{RESET}")
        sys.stdout.write("CANCEL:\n")
        return

    print_tty(f"{DIM}🖖 Spock {t('processing_ask', model=DEFAULT_MODEL)}{RESET}")

    if lang == "en":
        prompt = f"""{t('persona')}
The user requires an exact terminal command on Mac/Linux for the following task:
Query: {query}

Respond ONLY in this valid JSON format:
{{
  "explicacion": "Brief 1-sentence explanation of what the command does in English.",
  "comando": "Exact executable terminal command, no markdown, no quotes"
}}"""
    else:
        prompt = f"""{t('persona')}
El usuario necesita un comando exacto para la siguiente tarea en su terminal Mac/Linux:
Consulta: {query}

Responde ÚNICAMENTE en este formato JSON válido:
{{
  "explicacion": "Explicación breve de 1 frase del comando y su lógica en español.",
  "comando": "Comando exacto de terminal ejecutable, sin explicaciones, sin markdown"
}}"""

    result = query_ollama_json(prompt)
    if "error" in result:
        print_tty(f"{RED}❌ Error: {result.get('message')}{RESET}")
        sys.stdout.write("CANCEL:\n")
        return

    explicacion = result.get("explicacion", "Command suggested.")
    comando = clean_command(result.get("comando", ""))

    if not comando:
        print_tty(f"{RED}❌ Could not formulate command.{RESET}")
        sys.stdout.write("CANCEL:\n")
        return

    lines = [
        f"{BOLD}{t('query_label')}{RESET} {query}",
        f"{DIM}{t('explanation_label')}{RESET} {explicacion}",
        f"{BOLD}{t('suggested_label')}{RESET}",
        f"  {GREEN}{BOLD}{comando}{RESET}"
    ]
    render_box(t("box_ask"), lines)
    interactive_menu(comando)

def handle_chat():
    lang = ensure_language()
    print_tty()
    print_tty(f"{CYAN}╭─ {BOLD}{MAGENTA}🖖 Spock{RESET} {CYAN}• {BOLD}{t('box_chat')}{RESET} {CYAN}" + "─" * 32 + f"{RESET}")
    print_tty(f"{CYAN}│{RESET} {t('chat_welcome_1')}")
    print_tty(f"{CYAN}│{RESET} {t('chat_welcome_2')}")
    print_tty(f"{CYAN}│{RESET} {DIM}{t('chat_welcome_3')} [{lang.upper()}]{RESET}")
    print_tty(f"{CYAN}╰" + "─" * (65) + f"{RESET}\n")

    conversation_context = None

    while True:
        try:
            prompt_symbol = f"{MAGENTA}🖖 spock{RESET} {CYAN}❯{RESET} "
            user_input = input(prompt_symbol).strip()
        except (KeyboardInterrupt, EOFError):
            print_tty(f"\n{MAGENTA}🖖 Spock:{RESET} {t('chat_session_ended')}")
            break

        if not user_input:
            continue

        if user_input.lower() in ("exit", "quit", "q"):
            print_tty(f"{MAGENTA}🖖 Spock:{RESET} {t('chat_farewell')}")
            break

        if user_input.lower() == "clear":
            os.system("clear")
            continue

        if user_input.lower() in ("lang", "idioma"):
            handle_lang([])
            lang = ensure_language()
            continue

        prompt = f"""{t('persona')}
The user is interacting with you directly:
"{user_input}"

Respond in your logical Vulcan character with clarity, precision, and elegance."""

        print_tty(f"\n{MAGENTA}🖖 Spock:{RESET} ", end="")
        _, conversation_context = stream_ollama_text(prompt, context=conversation_context)
        print_tty()

def handle_query(query_parts: list):
    lang = ensure_language()
    query = " ".join(query_parts).strip()
    if not query:
        handle_chat()
        return

    cmd_keywords = [
        "como", "cómo", "comando", "ver", "listar", "borrar", "eliminar",
        "matar", "buscar", "instalar", "puerto", "proceso", "git", "docker",
        "crear", "mover", "copiar", "permisos", "chmod", "curl", "find",
        "how", "kill", "list", "show", "delete", "search", "port", "process"
    ]
    query_lower = query.lower()
    is_command_request = any(k in query_lower for k in cmd_keywords)

    if is_command_request and len(query.split()) < 14:
        handle_ask(query)
    else:
        print_tty()
        print_tty(f"{CYAN}╭─ {BOLD}{MAGENTA}🖖 Spock{RESET} {CYAN}• {BOLD}{t('box_query')}{RESET} {CYAN}" + "─" * 44 + f"{RESET}\n")
        prompt = f"""{t('persona')}
Query / Request:
{query}

Provide a logically impeccable, technically sharp, and didactic response."""
        stream_ollama_text(prompt)
        print_tty(f"\n{CYAN}╰" + "─" * (65) + f"{RESET}\n")

# ==============================================================================
# ENTRADA PRINCIPAL (CLI)
# ==============================================================================
def main():
    if len(sys.argv) < 2:
        handle_chat()
        return

    command = sys.argv[1].lower()
    args = sys.argv[2:]

    if command in ("lang", "language", "idioma"):
        handle_lang(args)
    elif command in ("get-lang", "lang-code"):
        sys.stdout.write(ensure_language() + "\n")
    elif command == "explain":
        handle_explain(args)
    elif command == "debug":
        handle_debug(args)
    elif command == "chat":
        handle_chat()
    elif command == "ask":
        query = " ".join(args)
        handle_ask(query)
    elif command == "fix":
        cmd = args[0] if len(args) > 0 else ""
        code = args[1] if len(args) > 1 else "1"
        err = " ".join(args[2:]) if len(args) > 2 else ""
        handle_fix(cmd, code, err)
    elif command == "query":
        handle_query(args)
    else:
        handle_query(sys.argv[1:])

if __name__ == "__main__":
    main()
