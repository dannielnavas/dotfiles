local wezterm = require 'wezterm'
local act = wezterm.action
local nf = wezterm.nerdfonts
local config = wezterm.config_builder()

-- Detectar si corre en Windows para entrar automáticamente a WSL2
if wezterm.target_triple:find("windows") then
  config.default_domain = 'WSL:Ubuntu'
end

----------------------------------------------------
-- 1. APARIENCIA Y FUENTE
----------------------------------------------------
config.color_scheme = 'Tokyo Night'

config.font = wezterm.font_with_fallback {
  { family = 'Victor Mono', weight = 'Medium' },
  'JetBrainsMono Nerd Font',
  'Apple Color Emoji',
}
config.font_size = 14
config.line_height = 1.1
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }

-- Transparencia y desenfoque nativo de macOS
config.window_background_opacity = 0.60
config.macos_window_background_blur = 30
config.window_padding = {
  left = 14,
  right = 14,
  top = 12,
  bottom = 12,
}

-- Quita la barra de título conservando el redimensionado
config.window_decorations = 'RESIZE'

-- Atenúa paneles inactivos
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.6 }

----------------------------------------------------
-- 2. RENDIMIENTO Y COMPORTAMIENTO
----------------------------------------------------
config.front_end = 'WebGpu'
config.max_fps = 120
config.animation_fps = 60
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_max_width = 36
config.hide_tab_bar_if_only_one_tab = false

config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500
config.scrollback_lines = 20000
config.scroll_to_bottom_on_input = true
config.alternate_buffer_wheel_scroll_speed = 3
config.audible_bell = 'Disabled'
config.hide_mouse_cursor_when_typing = true
config.window_close_confirmation = 'NeverPrompt'
config.native_macos_fullscreen_mode = false

-- Delimitadores al hacer doble clic (útil para URLs y rutas)
config.selection_word_boundary = " \t\n{}[]()\"'`,;:│"

-- Option izquierda = Alt (Neovim, readline, tmux)
-- Option derecha = acentos y caracteres especiales de macOS
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

----------------------------------------------------
-- 3. ENLACES CLICABLES
----------------------------------------------------
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- "org/repo#123" abre el issue en GitHub
table.insert(config.hyperlink_rules, {
  regex = [[\b([\w.-]+/[\w.-]+)#(\d+)\b]],
  format = 'https://github.com/$1/issues/$2',
})

----------------------------------------------------
-- 4. WORKSPACE INICIAL
----------------------------------------------------
config.default_workspace = 'main'

wezterm.on('gui-startup', function()
  local _, _, window = wezterm.mux.spawn_window { workspace = 'main' }
  window:gui_window():maximize()
end)

----------------------------------------------------
-- 5. PLUGINS
----------------------------------------------------
-- Plugin: resurrect.wezterm
local resurrect = wezterm.plugin.require('https://github.com/MLFlexer/resurrect.wezterm')

-- Plugin: bar.wezterm (Barra inferior de estado)
local bar = wezterm.plugin.require('https://github.com/adriankarlen/bar.wezterm')
bar.apply_to_config(config, {
  position = 'bottom',
  max_width = 36,
  modules = {
    tabs = {
      active_tab_fg = 4,
      inactive_tab_fg = 6,
    },
    workspace = { enabled = true },
    leader = { enabled = true },
    cwd = { enabled = true },
    hostname = { enabled = true, color = 8 },
    username = { enabled = true, color = 6 },
    spotify = { enabled = false, color = 2 },
    clock = { enabled = true, format = '%H:%M' },
  },
})

----------------------------------------------------
-- 6. PRESENTACIÓN MEJORADA DE PESTAÑAS (Pill Style)
----------------------------------------------------
local function get_process_info(tab)
  local pane = tab.active_pane
  local process_name = pane.foreground_process_name or ""
  local name = process_name:gsub("(.*[/\\])(.*)", "%2"):lower()

  -- Extraer la carpeta de trabajo actual (CWD)
  local cwd = ""
  local cwd_uri = pane.current_working_dir
  if cwd_uri then
    local path = ""
    if type(cwd_uri) == "userdata" or type(cwd_uri) == "table" then
      path = cwd_uri.file_path or ""
    elseif type(cwd_uri) == "string" then
      path = cwd_uri:gsub("^file://[^/]*", "")
    end

    local home = os.getenv("HOME") or ""
    if home ~= "" and path == home then
      cwd = "~"
    elseif path ~= "" then
      cwd = path:match("([^/]+)$") or path
    end
  end

  -- Si el usuario renombró la pestaña manualmente
  if tab.tab_title and #tab.tab_title > 0 then
    return nf.cod_terminal, tab.tab_title
  end

  local icon = nf.cod_terminal
  local title = "shell"

  if name:find("nvim") or name:find("vim") then
    icon = nf.custom_neovim
    title = (cwd ~= "" and cwd ~= "~") and ("nvim: " .. cwd) or "neovim"
  elseif name:find("git") or name:find("lazygit") then
    icon = nf.dev_git
    title = (name:find("lazygit")) and "lazygit" or "git"
    if cwd ~= "" and cwd ~= "~" then
      title = title .. " (" .. cwd .. ")"
    end
  elseif name:find("node") or name:find("npm") or name:find("pnpm") or name:find("yarn") or name:find("bun") then
    icon = nf.dev_nodejs_small
    title = name
    if cwd ~= "" and cwd ~= "~" then
      title = title .. " (" .. cwd .. ")"
    end
  elseif name:find("python") or name:find("py") then
    icon = nf.dev_python
    title = "python"
    if cwd ~= "" and cwd ~= "~" then
      title = title .. " (" .. cwd .. ")"
    end
  elseif name:find("cargo") or name:find("rust") then
    icon = nf.dev_rust
    title = "cargo"
    if cwd ~= "" and cwd ~= "~" then
      title = title .. " (" .. cwd .. ")"
    end
  elseif name:find("docker") then
    icon = nf.linux_docker
    title = "docker"
  elseif name:find("ssh") then
    icon = nf.md_remote_desktop
    title = "ssh"
  elseif name:find("htop") or name:find("btop") or name:find("top") then
    icon = nf.md_chart_bell_curve
    title = name
  elseif name:find("zsh") or name:find("bash") or name:find("sh") or name:find("fish") or name == "" then
    icon = nf.cod_terminal
    title = cwd ~= "" and cwd or "terminal"
  else
    icon = nf.cod_terminal
    title = name
    if cwd ~= "" and cwd ~= "~" then
      title = title .. " (" .. cwd .. ")"
    end
  end

  -- Indicador de paneles divididos (Splits) y Zoom
  local badges = ""
  if #tab.panes > 1 then
    badges = badges .. " " .. nf.cod_multiple_windows .. #tab.panes
  end
  if pane.is_zoomed then
    badges = badges .. " " .. nf.md_fullscreen
  end

  return icon, title .. badges
end

wezterm.on("format-tab-title", function(tab, tabs, panes, conf, hover, max_width)
  local icon, title = get_process_info(tab)
  local index = tostring(tab.tab_index + 1)

  local bar_bg = "transparent"
  local pill_bg, pill_fg, icon_fg, num_fg

  if tab.is_active then
    -- Píldora activa: fondo azul Tokyo Night, texto oscuro nítido
    pill_bg = "#7aa2f7"
    pill_fg = "#15161e"
    icon_fg = "#15161e"
    num_fg = "#15161e"
  elseif hover then
    -- Píldora hover: fondo resaltado, texto brillante
    pill_bg = "#292e42"
    pill_fg = "#c0caf5"
    icon_fg = "#7dcfff"
    num_fg = "#7aa2f7"
  else
    -- Píldora inactiva: tono sutil integrado con el tema
    pill_bg = "#1f2335"
    pill_fg = "#9aa5ce"
    icon_fg = "#7aa2f7"
    num_fg = "#565f89"
  end

  -- Truncar si el título excede el ancho máximo
  local max_len = conf.tab_max_width or 32
  if #title > max_len - 8 then
    title = wezterm.truncate_right(title, max_len - 11) .. "…"
  end

  return {
    { Background = { Color = bar_bg } },
    { Foreground = { Color = pill_bg } },
    { Text = nf.ple_left_half_circle_thick },

    { Background = { Color = pill_bg } },
    { Foreground = { Color = num_fg } },
    { Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
    { Text = " " .. index .. " " },

    { Background = { Color = pill_bg } },
    { Foreground = { Color = icon_fg } },
    { Text = icon .. " " },

    { Background = { Color = pill_bg } },
    { Foreground = { Color = pill_fg } },
    { Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
    { Text = title .. " " },

    { Background = { Color = bar_bg } },
    { Foreground = { Color = pill_bg } },
    { Text = nf.ple_right_half_circle_thick },

    { Background = { Color = bar_bg } },
    { Text = " " },
  }
end)

----------------------------------------------------
-- 7. ATAJOS DE TECLADO (Unificados)
----------------------------------------------------
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

config.keys = {
  -- === Splits y Paneles (Soporta estilo Warp y Leader) ===
  { key = 'd', mods = 'CMD', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'CMD|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'w', mods = 'CMD', action = act.CloseCurrentPane { confirm = false } },
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },

  -- === Navegación entre paneles (Alt+Flechas y Leader+hjkl) ===
  { key = 'LeftArrow',  mods = 'OPT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'OPT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'OPT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow',  mods = 'OPT', action = act.ActivatePaneDirection 'Down' },
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

  -- === Redimensionar paneles (Leader + Flechas) ===
  { key = 'LeftArrow',  mods = 'LEADER', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'RightArrow', mods = 'LEADER', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'UpArrow',    mods = 'LEADER', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'DownArrow',  mods = 'LEADER', action = act.AdjustPaneSize { 'Down', 5 } },

  -- === Pestañas (Navegación y Gestión) ===
  { key = 't', mods = 'CMD', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'LeftArrow', mods = 'CMD|ALT', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CMD|ALT', action = act.ActivateTabRelative(1) },

  -- === Workspaces ===
  { key = 's', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  {
    key = 'c',
    mods = 'LEADER',
    action = act.PromptInputLine {
      description = 'Nombre del workspace:',
      action = wezterm.action_callback(function(window, pane, line)
        if line and line ~= '' then
          window:perform_action(act.SwitchToWorkspace { name = line }, pane)
        end
      end),
    },
  },

  -- === Búsqueda, QuickSelect y Copia ===
  { key = 'f', mods = 'CMD', action = act.Search { CaseSensitiveString = '' } },
  { key = 'Space', mods = 'LEADER', action = act.QuickSelect },
  { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },
  { key = 'k', mods = 'CMD', action = act.ClearScrollback 'ScrollbackAndViewport' },

  -- === Zoom de fuente ===
  { key = '=', mods = 'CMD', action = act.IncreaseFontSize },
  { key = '+', mods = 'CMD', action = act.IncreaseFontSize },
  { key = '-', mods = 'CMD', action = act.DecreaseFontSize },
  { key = '0', mods = 'CMD', action = act.ResetFontSize },

  -- === Paleta de comandos ===
  { key = 'p', mods = 'CMD|SHIFT', action = act.ActivateCommandPalette },

  -- === Sesiones (Resurrect) ===
  {
    key = 'S',
    mods = 'LEADER|SHIFT',
    action = wezterm.action_callback(function(_, _)
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
    end),
  },
  {
    key = 'R',
    mods = 'LEADER|SHIFT',
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
        local type = string.match(id, '^([^/]+)')
        id = string.match(id, '([^/]+)$')
        id = string.gsub(id, '.json$', '')
        if type == 'workspace' then
          local state = resurrect.load_state(id, 'workspace')
          resurrect.workspace_state.restore_workspace(state, {
            window = win:mux_window(),
          })
        end
      end)
    end),
  },
}

-- Atajos rápidos directos para cambiar a pestaña 1..8 y última (9) con CMD
for i = 1, 8 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'CMD',
    action = act.ActivateTab(i - 1),
  })
end
table.insert(config.keys, {
  key = '9',
  mods = 'CMD',
  action = act.ActivateTab(-1),
})

return config
