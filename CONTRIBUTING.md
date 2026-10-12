# Contributing to Dotfiles & Dilix AI Suite

Thank you for your interest in contributing to this project! We welcome contributions, bug reports, and suggestions to make this terminal setup and the Dilix AI suite even better.

---

## 🧭 How You Can Help

1. **Bug Reports & Fixes**: Found a problem in `install.sh`, Zsh aliases, or Dilix on your OS? Let us know or submit a PR.
2. **Platform Support**: Improvements for macOS (Apple Silicon / Intel), CachyOS / Arch Linux, Ubuntu / Debian, or WSL2.
3. **Features & Tools**: New modern CLI integrations, themes, Fastfetch presets, or Dilix capabilities.
4. **Documentation**: Improvements in English and Spanish translations or guide clarifications.

---

## 🛠️ Development & Local Testing

### 1. Fork & Clone
```bash
git clone https://github.com/<your-username>/dotfiles.git
cd dotfiles
```

### 2. Testing the Installer
Before submitting changes to `install.sh`:
- Test dry-runs or specific operating system flags:
  ```bash
  bash -n install.sh
  ./install.sh --help
  ```
- Always verify that the script does not break backwards compatibility across macOS, Arch/CachyOS, Ubuntu, and WSL2.

### 3. Testing Dilix AI Plugin
- Test Python syntax:
  ```bash
  python3 -m py_compile zsh/plugins/dilix/dilix.py
  ```
- Verify CLI command parsing:
  ```bash
  python3 zsh/plugins/dilix/dilix.py --help
  ```

---

## 📝 Commit Conventions

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` A new feature or configuration capability
- `fix:` A bug fix in scripts or plugins
- `docs:` Documentation updates in README or contributing files
- `style:` Formatting changes with no production code changes
- `refactor:` Code improvements that neither fix bugs nor add features
- `chore:` Maintenance tasks, `.gitignore` updates, or build configs

---

## 🚀 Submitting a Pull Request

1. Create a dedicated branch:
   ```bash
   git checkout -b feat/my-awesome-improvement
   ```
2. Commit your changes with descriptive messages.
3. Push to your fork:
   ```bash
   git push origin feat/my-awesome-improvement
   ```
4. Open a Pull Request on GitHub against the `main` branch.
5. Fill out the PR template with details of what was changed and on which OS you tested it.

---

## 🤝 Code of Conduct

Please adhere to our [Code of Conduct](file:///Users/dannielnavas/dotfiles/CODE_OF_CONDUCT.md) in all project interactions.
