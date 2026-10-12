#!/usr/bin/env python3
"""
Spock - Asistente Lógico de Terminal y Copiloto de Programación para Zsh.
Inspirado en el Oficial Científico Spock: altamente lógico, analítico, conciso y natural.
Capaz de sugerir comandos ('ask'), depurar errores ('fix'/'debug'), explicar código ('explain')
y dialogar directamente en modo interactivo ('chat').
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

# Estilos y Colores ANSI
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

SPOCK_PERSONA = (
    "Eres el Oficial Científico Spock de la USS Enterprise, adaptado como copiloto de terminal e ingeniero de software lógico en Mac/Linux.\n"
    "Personalidad y directrices:\n"
    "- Eres supremamente lógico, analítico, cortés, sereno y perspicaz.\n"
    "- Utilizas expresiones sutiles vulcanas como: 'Fascinante.', 'Lógicamente...', 'Desde una perspectiva puramente racional...', 'Es altamente probable que...', 'El curso de acción óptimo es...'.\n"
    "- Hablas en un español fluido, natural y elegante. No eres una máquina aburrida ni una caricatura: eres un compañero de programación brillante, con rigor técnico y agudeza mental.\n"
    "- Ofreces lógica precisa: vas directo a la raíz del problema, sin rodeos innecesarios pero con claridad didáctica.\n"
)

# ==============================================================================
# UTILIDADES DE TERMINAL Y E/S
# ==============================================================================
def print_tty(msg="", end="\n"):
    """Imprime directamente en la terminal (/dev/tty) para mantener stdout libre si se redirige."""
    try:
        with open("/dev/tty", "w") as tty:
            tty.write(msg + end)
            tty.flush()
    except Exception:
        sys.stderr.write(msg + end)
        sys.stderr.flush()

def read_key():
    """Lee una sola pulsación de tecla desde la terminal de forma no bloqueante."""
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
    """Elimina formato markdown redundante o backticks del comando extraído."""
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
    """Copia texto al portapapeles en macOS (pbcopy), Linux o WSL."""
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
    """Verifica si Ollama está en línea."""
    try:
        req = urllib.request.Request(f"{OLLAMA_HOST}/api/tags", headers={"User-Agent": "Spock/1.0"})
        with urllib.request.urlopen(req, timeout=1.5) as resp:
            return resp.status == 200
    except Exception:
        return False

def get_terminal_scrollback(lines=30):
    """Extrae líneas del scrollback de WezTerm si está disponible."""
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
    """Muestra una caja delimitada con bordes redondeados y colores limpios."""
    print_tty()
    print_tty(f"{CYAN}╭─ {BOLD}{MAGENTA}🖖 Spock{RESET} {CYAN}• {BOLD}{title}{RESET} {CYAN}" + "─" * 42 + f"{RESET}")
    for line in content_lines:
        print_tty(f"{CYAN}│{RESET} {line}")
    print_tty(f"{CYAN}╰" + "─" * (55) + f"{RESET}")

def interactive_menu(command: str):
    """
    Menú de acción para comandos sugeridos:
    [e / Enter] Ejecutar
    [m] Modificar / Cargar en buffer del prompt (print -z)
    [c] Copiar al portapapeles
    [q] Cancelar
    """
    while True:
        menu_text = (
            f" {BOLD}Acción:{RESET} "
            f"[{GREEN}↵ Enter{RESET}/{GREEN}e{RESET}] Ejecutar  "
            f"[{YELLOW}m{RESET}] En el prompt  "
            f"[{CYAN}c{RESET}] Copiar  "
            f"[{DIM}q{RESET}] Salir: "
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
                print_tty(f" {GREEN}✔ Copiado al portapapeles con éxito.{RESET}")
            else:
                print_tty(f" {YELLOW}⚠️ No se pudo copiar al portapapeles.{RESET}")
        elif key in ("q", "Q", "\x03", "\x1b", "ESC"):
            sys.stdout.write("CANCEL:\n")
            sys.stdout.flush()
            break

# ==============================================================================
# CLIENTE OLLAMA (STREAMING Y NO-STREAMING)
# ==============================================================================
def query_ollama_json(prompt: str) -> dict:
    """Consulta estructurada en JSON sin streaming."""
    if not check_ollama():
        return {
            "error": "OLLAMA_OFFLINE",
            "message": f"Ollama no responde en {OLLAMA_HOST}. Inícialo con 'ollama serve' o abre la aplicación."
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
    """Consulta de texto en streaming en tiempo real con efecto fluido."""
    if not check_ollama():
        print_tty(f"{RED}❌ Error: Ollama no responde en {OLLAMA_HOST}. Inícialo con 'ollama serve'.{RESET}")
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
        print_tty() # Salto de línea al terminar
        return "".join(full_response), final_context
    except Exception as e:
        print_tty(f"\n{RED}❌ Error en comunicación con Ollama: {e}{RESET}")
        return "".join(full_response), final_context

# ==============================================================================
# FUNCIONALIDAD 1: EXPLICAR CÓDIGO (EXPLAIN)
# ==============================================================================
def handle_explain(args: list):
    """Explica código fuente, archivos o comandos de forma lógica y estructurada."""
    code_content = ""
    source_label = ""

    # Caso A: Entrada por tubería (pipe): cat file | spock explain
    if not sys.stdin.isatty():
        code_content = sys.stdin.read().strip()
        source_label = "Entrada estándar (stdin)"

    # Caso B: Archivo pasado como argumento: spock explain main.py
    elif args and os.path.isfile(args[0]):
        filepath = args[0]
        try:
            with open(filepath, "r", errors="ignore") as f:
                lines = f.readlines()
            if len(lines) > 400:
                code_content = "".join(lines[:400])
                source_label = f"{filepath} (primeras 400 líneas)"
            else:
                code_content = "".join(lines)
                source_label = filepath
        except Exception as e:
            print_tty(f"{RED}❌ No se pudo leer el archivo '{filepath}': {e}{RESET}")
            return

    # Caso C: Fragmento de código o comando pasado directamente
    elif args:
        code_content = " ".join(args).strip()
        source_label = "Fragmento / Comando"
    else:
        print_tty(f"{YELLOW}Uso de 'spock explain':{RESET}")
        print_tty("  spock explain ruta/al/archivo.py")
        print_tty("  spock explain \"git rebase -i HEAD~3\"")
        print_tty("  git diff | spock explain")
        return

    if not code_content:
        print_tty(f"{YELLOW}💡 No se detectó código ni contenido para analizar.{RESET}")
        return

    print_tty()
    print_tty(f"{CYAN}╭─ {BOLD}{MAGENTA}🖖 Spock{RESET} {CYAN}• {BOLD}Análisis Lógico de Código: {source_label}{RESET} {CYAN}" + "─" * 25 + f"{RESET}")
    print_tty(f"{DIM}Procesando estructura y deduciendo funcionamiento con {DEFAULT_MODEL}...{RESET}\n")

    prompt = f"""{SPOCK_PERSONA}
Tu misión es explicar y diseccionar el siguiente código o comando con rigor analítico.
Origen: {source_label}

```
{code_content}
```

Estructura tu respuesta exactamente así:
1. **Propósito Lógico General**: (1 o 2 oraciones concisas de qué hace).
2. **Flujo de Ejecución y Mecánica Interna**: (desglose paso a paso de los componentes clave).
3. **Evaluación Crítica**: (eficiencia algorítmica, posibles casos borde, vulnerabilidades o mejoras si las hay).

Mantén tu tono vulcaniano: sobrio, impecable y directo al grano."""

    stream_ollama_text(prompt)
    print_tty(f"{CYAN}╰" + "─" * 65 + f"{RESET}\n")

# ==============================================================================
# FUNCIONALIDAD 2: DEPURAR ERRORES (DEBUG / FIX)
# ==============================================================================
def handle_debug(args: list):
    """Depuración profunda de errores, logs o fallos de ejecución."""
    error_content = ""
    source = ""

    if not sys.stdin.isatty():
        error_content = sys.stdin.read().strip()
        source = "Registro de error (stdin)"
    elif args and os.path.isfile(args[0]):
        try:
            with open(args[0], "r", errors="ignore") as f:
                error_content = f.read()[-3000:]
            source = f"Archivo {args[0]}"
        except Exception as e:
            print_tty(f"{RED}❌ No se pudo leer {args[0]}: {e}{RESET}")
            return
    elif args:
        error_content = " ".join(args).strip()
        source = "Error proporcionado"
    else:
        error_content = get_terminal_scrollback(30)
        source = "Último registro de la terminal"

    if not error_content:
        print_tty(f"{YELLOW}💡 No se proporcionó ningún mensaje o traza de error para depurar.{RESET}")
        return

    print_tty()
    print_tty(f"{CYAN}╭─ {BOLD}{MAGENTA}🖖 Spock{RESET} {CYAN}• {BOLD}Depuración Lógica y Causa Raíz{RESET} {CYAN}" + "─" * 30 + f"{RESET}")
    print_tty(f"{DIM}Aislando variables y deduciendo el origen de la anomalía...{RESET}\n")

    prompt = f"""{SPOCK_PERSONA}
El usuario solicita depuración de una anomalía o error en su sistema/código.
Contexto / Traza del error ({source}):
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
    """Diagnóstico rápido del último comando fallido de terminal con menú de acción."""
    if not last_cmd.strip():
        print_tty(f"{YELLOW}💡 No hay ningún comando previo registrado para analizar.{RESET}")
        sys.stdout.write("CANCEL:\n")
        return

    scrollback = error_msg if error_msg else get_terminal_scrollback(25)

    print_tty(f"{DIM}🖖 Spock examinando la anomalía con {DEFAULT_MODEL}...{RESET}")

    prompt = f"""{SPOCK_PERSONA}
El siguiente comando de terminal acaba de fallar:
Comando ejecutado: {last_cmd}
Código de salida (exit code): {last_code}
Directorio actual: {os.getcwd()}
Contexto / Salida de terminal:
{scrollback}

Analiza la causa lógica del fallo y formula la corrección exacta.
Responde ÚNICAMENTE en este formato JSON válido:
{{
  "causa": "Explicación directa de 1 frase del por qué falló de manera lógica.",
  "que_hacer": "Instrucción clara y concisa de qué toca hacer.",
  "comando": "Comando exacto de terminal corregido para solucionar o reintentar, sin markdown ni explicaciones adicionales"
}}"""

    result = query_ollama_json(prompt)
    if "error" in result:
        print_tty(f"{RED}❌ Error: {result.get('message')}{RESET}")
        sys.stdout.write("CANCEL:\n")
        return

    causa = result.get("causa", "El comando devolvió un código de error inesperado.")
    que_hacer = result.get("que_hacer", "Verifique la sintaxis o dependencias.")
    comando = clean_command(result.get("comando", ""))

    lines = [
        f"{BOLD}{RED}❌ Falló:{RESET} {CYAN}{last_cmd}{RESET} {DIM}(exit code: {last_code}){RESET}",
        f"{BOLD}🔍 Causa lógica:{RESET} {causa}",
        f"{BOLD}💡 Qué toca hacer:{RESET} {que_hacer}",
    ]
    if comando:
        lines.append(f"{BOLD}⚡ Solución sugerida:{RESET}")
        lines.append(f"  {GREEN}{BOLD}{comando}{RESET}")

    render_box("Diagnóstico y Solución de Error", lines)

    if comando:
        interactive_menu(comando)
    else:
        sys.stdout.write("CANCEL:\n")

# ==============================================================================
# FUNCIONALIDAD 3: CONSULTA DE COMANDOS (ASK)
# ==============================================================================
def handle_ask(query: str):
    """Consulta en lenguaje natural para obtener comandos precisos con menú."""
    if not query.strip():
        print_tty(f"{YELLOW}Uso: ask \"consulta sobre lo que deseas hacer en la terminal\"{RESET}")
        sys.stdout.write("CANCEL:\n")
        return

    print_tty(f"{DIM}🖖 Spock consultando {DEFAULT_MODEL}...{RESET}")
    prompt = f"""{SPOCK_PERSONA}
El usuario necesita un comando exacto para la siguiente tarea en su terminal Mac/Linux:
Consulta: {query}

Responde ÚNICAMENTE en este formato JSON válido:
{{
  "explicacion": "Explicación breve de 1 frase del comando y su lógica.",
  "comando": "Comando exacto de terminal ejecutable, sin explicaciones, sin markdown"
}}"""

    result = query_ollama_json(prompt)
    if "error" in result:
        print_tty(f"{RED}❌ Error: {result.get('message')}{RESET}")
        sys.stdout.write("CANCEL:\n")
        return

    explicacion = result.get("explicacion", "Comando sugerido.")
    comando = clean_command(result.get("comando", ""))

    if not comando:
        print_tty(f"{RED}❌ No se pudo formular un comando para la consulta.{RESET}")
        sys.stdout.write("CANCEL:\n")
        return

    lines = [
        f"{BOLD}Consulta:{RESET} {query}",
        f"{DIM}Explicación:{RESET} {explicacion}",
        f"{BOLD}Comando sugerido:{RESET}",
        f"  {GREEN}{BOLD}{comando}{RESET}"
    ]
    render_box("Sugerencia de Comando", lines)
    interactive_menu(comando)

# ==============================================================================
# FUNCIONALIDAD 4: CHAT INTERACTIVO DIRECTO (CONVERSACIÓN CON SPOCK)
# ==============================================================================
def handle_chat():
    """Inicia una sesión de diálogo interactivo directo con Spock en la terminal."""
    print_tty()
    print_tty(f"{CYAN}╭─ {BOLD}{MAGENTA}🖖 Spock{RESET} {CYAN}• {BOLD}Canal de Comunicación Directo{RESET} {CYAN}" + "─" * 32 + f"{RESET}")
    print_tty(f"{CYAN}│{RESET} Oficial Científico Spock a su servicio.")
    print_tty(f"{CYAN}│{RESET} Puedo explicar código, depurar errores y analizar lógica de sistemas.")
    print_tty(f"{CYAN}│{RESET} {DIM}Escribe 'q' o 'exit' para salir, 'clear' para limpiar pantalla.{RESET}")
    print_tty(f"{CYAN}╰" + "─" * (65) + f"{RESET}\n")

    conversation_context = None

    while True:
        try:
            prompt_symbol = f"{MAGENTA}🖖 spock{RESET} {CYAN}❯{RESET} "
            user_input = input(prompt_symbol).strip()
        except (KeyboardInterrupt, EOFError):
            print_tty(f"\n{MAGENTA}🖖 Spock:{RESET} Larga vida y prosperidad. Sesión finalizada.")
            break

        if not user_input:
            continue

        if user_input.lower() in ("exit", "quit", "q"):
            print_tty(f"{MAGENTA}🖖 Spock:{RESET} Larga vida y prosperidad.")
            break

        if user_input.lower() == "clear":
            os.system("clear")
            continue

        prompt = f"""{SPOCK_PERSONA}
El usuario interactúa contigo directamente:
"{user_input}"

Responde en tu carácter vulcaniano con sabiduría, precisión técnica, claridad y naturalidad."""

        print_tty(f"\n{MAGENTA}🖖 Spock:{RESET} ", end="")
        _, conversation_context = stream_ollama_text(prompt, context=conversation_context)
        print_tty()

# ==============================================================================
# FUNCIONALIDAD 5: CONSULTA INTELIGENTE DIRECTA (QUERY)
# ==============================================================================
def handle_query(query_parts: list):
    """Enruta inteligentemente entre sugerir un comando ejecutable o responder como Spock."""
    query = " ".join(query_parts).strip()
    if not query:
        handle_chat()
        return

    # Palabras clave que denotan solicitud de comando de terminal
    cmd_keywords = [
        "como", "cómo", "comando", "ver", "listar", "borrar", "eliminar",
        "matar", "buscar", "instalar", "puerto", "proceso", "git", "docker",
        "crear", "mover", "copiar", "permisos", "chmod", "curl", "find"
    ]
    query_lower = query.lower()
    is_command_request = any(k in query_lower for k in cmd_keywords)

    if is_command_request and len(query.split()) < 14:
        handle_ask(query)
    else:
        # Pregunta conceptual / técnica: respuesta directa con streaming
        print_tty()
        print_tty(f"{CYAN}╭─ {BOLD}{MAGENTA}🖖 Spock{RESET} {CYAN}• {BOLD}Análisis Lógico{RESET} {CYAN}" + "─" * 44 + f"{RESET}\n")
        prompt = f"""{SPOCK_PERSONA}
Pregunta o solicitud del usuario:
{query}

Ofrece una respuesta de élite, sumamente lógica, clara y técnicamente impecable."""
        stream_ollama_text(prompt)
        print_tty(f"\n{CYAN}╰" + "─" * (65) + f"{RESET}\n")

# ==============================================================================
# ENTRADA PRINCIPAL
# ==============================================================================
def main():
    if len(sys.argv) < 2:
        # Invocación directa 'spock' -> entra al chat interactivo
        handle_chat()
        return

    command = sys.argv[1]
    args = sys.argv[2:]

    if command == "explain":
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
        # Invocación directa: spock "texto..."
        handle_query(sys.argv[1:])

if __name__ == "__main__":
    main()
