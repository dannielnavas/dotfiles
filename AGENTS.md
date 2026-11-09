# AGENTS.md

Dotfiles for WezTerm + Zsh + Starship + Fastfetch, cross-platform: macOS, CachyOS/Arch, Ubuntu/Debian, WSL2. Target aesthetic is Warp-like minimal (single tab bar, clean prompt, no banner). No build, test, or lint runner — validation is `bash -n` (see `.github/workflows/ci.yml`).

## Validate

```bash
bash -n install.sh                                  # CI check
bash -n tapes/render_all.sh                         # CI check if file present
./install.sh --help                                 # shows all flags
zsh -n zsh/.zshrc                                   # manual sanity (not in CI)
STARSHIP_CONFIG=startship/starship.toml starship explain
wezterm ls-fonts                                    # parses .wezterm.lua (check for ERROR lines)
```

## Install (entrypoint)

```bash
./install.sh                                        # interactive: language (default ES, EN if $LANG^en) then OS auto-detected via $OSTYPE, /etc/os-release, $WSL_DISTRO_NAME
./install.sh --en --macos                           # non-interactive; flags: --en|--es, --macos|--cachyos|--linux|--wsl2 (+ aliases)
```

`install.sh` is destructive by design: `rm -rf ~/.zshrc ~/.wezterm.lua ~/.config/starship.toml ~/.config/fastfetch`, then symlinks the repo files there. On Linux it also links `wezterm/.wezterm.lua` → `~/.config/wezterm/wezterm.lua`. Do not change this to copies — editing the repo file must take effect in the home dir.

## Layout (non-obvious spellings)

- `zsh/.zshrc`, `wezterm/.wezterm.lua`, `startship/starship.toml` (note `startship`, not `starship/`), `fastfetch/*.jsonc` (JSONC — comments allowed, not strict JSON).
- `install.sh` downloads `fastfetch` macOS logos from `sqlsec/fastfetch` zip into `fastfetch/macos/` if missing (*.zip ignored). `fastfetch/config.jsonc` picks a random logo via `find … | sort -R`.

## Nacel is external — do not touch it here

Nacel AI (`github.com/dannielnavas/nacel`) lives outside this repo. `install.sh` and `zsh/.zshrc` clone it to `~/nacel` or `~/.nacel`, symlink `nacel` (+ legacy alias `dilix`) into `~/.local/bin`, write `~/.config/nacel/config.json` (`{lang, model: gemma2:2b}`), start Ollama (`localhost:11434`) and pull that model. Default model / service startup changes belong in the `nacel` repo, not here. `zsh/.zshrc` also auto-clones it.

## Bilingual rule

Repo is EN + ES throughout: README (EN then ES), `install.sh` via `echo_lang "$es" "$en"`, `zsh/.zshrc` / `wezterm/.wezterm.lua` comments (ES-first). Any user-facing change to `install.sh` or README must update both languages.

## Traps

- `tapes/*.tape`, `tapes/render_all.sh`, `tapes/README.md` are gitignored (only `tapes/*.gif` is tracked) — fixes there won't ship. `tapes/render_all.sh` also hardcodes a local Dilix landing path (`/Users/dannielnavas/Documents/Projects/dilix/public`) and needs `brew install vhs`.
- `zsh/.zshrc` shadows `ls`→`eza`, `cat`→`bat`, and hardcodes machine paths (`/Users/dannielnavas/.antigravity-ide/…`, `PNPM_HOME`) — fine locally, don't copy verbatim into docs. No `fastfetch` banner on startup (Warp clean start) — manual `ff` only.
- `wezterm/.wezterm.lua`: Warp-like single tab bar, text-only tabs (no pills/icons), `SteadyBlock` cursor, `TITLE | RESIZE` decorations. Keep `bar.wezterm` OUT — it duplicates the tab bar. Leader is `Ctrl+A` (timeout 1000ms); plugins load via `wezterm.plugin.require` URLs.
- `startship/starship.toml`: 2-line prompt (`dir + git` / `❯`), no `$fill`, `truncate_to_repo=true`. Tabs show `index · cwd` (renamed via `tab_title` if set).
- `.gitattributes` forces LF for `*.sh`, `*.zsh`, `*.lua`, `*.md`, `*.py` — don't commit CRLF.

## PRs

Targets `main`. Use Conventional Commits (`feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `chore:`), branch `feat/...`, and list tested platforms (macOS / CachyOS / Ubuntu / WSL2) in the PR body.
