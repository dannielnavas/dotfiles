local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Detectar si corre en Windows para entrar automáticamente a WSL2 (Ubuntu, CachyOS, etc.)
if wezterm.target_triple:find("windows") then
  local wsl_domains = wezterm.default_wsl_domains and wezterm.default_wsl_domains() or {}
  if #wsl_domains > 0 then
    config.default_domain = wsl_domains[1].name
  else
    config.default_domain = 'WSL:Ubuntu'
  end
end

----------------------------------------------------
-- 1. APARIENCIA Y FUENTE (estilo Warp: limpio, aireado, casi opaco)
----------------------------------------------------
config.color_scheme = 'Tokyo Night'

config.font = wezterm.font_with_fallback {
  'JetBrainsMono Nerd Font',
  'Apple Color Emoji',
}
config.font_size = 14
config.line_height = 1.25
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }
-- Victor Mono solo para cursiva (no como fuente principal: Warp usa mono limpia)
config.font_rules = {
  {
    italic = true,
    font = wezterm.font('Victor Mono', { italic = true }),
  },
}

-- Estilo Warp: ventana casi opaca, blur suave, padding amplio
config.window_background_opacity = 0.95
config.macos_window_background_blur = 18
config.window_padding = {
  left = 20,
  right = 20,
  top = 8,
  bottom = 16,
}

-- Traffic lights (cerrar/minimizar/maximizar) visibles en macOS.
-- TITLE | RESIZE = título arriba + tabs debajo. RESIZE solo los oculta.
-- Para que parezca UNA barra Warp, el título usa el mismo fondo que la tab bar.
config.window_decorations = 'TITLE | RESIZE'

-- Gradiente vertical sutil como Warp (título/tabs en #1a1b26 arriba)
config.window_background_gradient = {
  orientation = 'Vertical',
  colors = { '#1a1b26', '#16161e' },
}

-- Atenuado sutil de paneles inactivos (Warp no apaga los inactivos)
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.85 }

-- Scrollbar overlay: Warp no muestra scrollbar gruesa
config.enable_scroll_bar = false
config.visual_bell = { fade_in_duration_ms = 75, fade_out_duration_ms = 75 }

----------------------------------------------------
-- 2. RENDIMIENTO Y COMPORTAMIENTO
----------------------------------------------------
config.front_end = 'WebGpu'
config.max_fps = 120
config.animation_fps = 60
-- Estilo Warp: UNICA barra (la de tabs), arriba, simple. Sin bar.wezterm.
config.enable_tab_bar = true
config.use_fancy_tab_bar = true -- esquinas redondeadas como Warp
config.tab_max_width = 36
-- NUNCA ocultar: con true la barra desaparece con 1 pestaña y no se puede cambiar.
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = true -- "+" visible para crear pestaña
config.show_close_tab_button_in_tabs = true -- "x" visible para cerrar
config.colors = {
  tab_bar = {
    background = '#1a1b26', -- igual que el título: título + tabs se funden (Warp)
    active_tab = { fg_color = '#c0caf5', bg_color = '#24283b' },
    inactive_tab = { fg_color = '#7a82a6', bg_color = '#1a1b26' },
    inactive_tab_hover = { fg_color = '#7aa2f7', bg_color = '#24283b' },
    new_tab = { fg_color = '#7a82a6', bg_color = '#1a1b26' },
    new_tab_hover = { fg_color = '#c0caf5', bg_color = '#24283b' },
  },
}

config.default_cursor_style = 'SteadyBlock'
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
-- 5. PESTAÑAS — estilo Warp: texto plano pero distinguibles
--    "1 · dotfiles" = índice + carpeta (Ctrl+A , renombra).
--    Punto amarillo si hay salida nueva en segundo plano (como Warp).
----------------------------------------------------
local function cwd_basename(pane)
  local cwd = pane.current_working_dir
  if not cwd then return "" end
  local path = ""
  if type(cwd) == "userdata" or type(cwd) == "table" then
    path = cwd.file_path or ""
  elseif type(cwd) == "string" then
    path = cwd:gsub("^file://[^/]*", "")
  end
  path = path:gsub("/+$", "")
  local home = os.getenv("HOME") or ""
  if home ~= "" and path == home then return "~" end
  return path:match("([^/]+)$") or path
end

wezterm.on("format-tab-title", function(tab)
  local title = tab.tab_title
  if title == "" or title == nil then
    title = cwd_basename(tab.active_pane)
  end
  if title == "" or title == nil then
    title = tab.active_pane.title
  end
  if title == "" or title == nil then
    title = "shell"
  end
  local prefix = tostring(tab.tab_index + 1) .. " · "
  local suffix = " "
  -- Warp: punto = salida nueva sin leer en tab inactiva
  if not tab.is_active and tab.active_pane and tab.active_pane.has_unseen_output then
    suffix = " ● "
  end
  return prefix .. title .. suffix
end)

-- Título de ventana como Warp: carpeta actual
wezterm.on('format-window-title', function(tab)
  local title = tab.tab_title
  if title == "" or title == nil then
    title = cwd_basename(tab.active_pane)
  end
  if title == "" or title == nil then title = "terminal" end
  return title
end)

----------------------------------------------------
-- 6. PLUGINS (solo resurrect; bar.wezterm eliminado: duplicaba la barra)
----------------------------------------------------
local resurrect = wezterm.plugin.require('https://github.com/MLFlexer/resurrect.wezterm')

----------------------------------------------------
-- 7. ATAJOS DE TECLADO (Unificados)
----------------------------------------------------
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

config.keys = {
  -- === Splits y Paneles (Soporta estilo Dilix y Leader) ===
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

  -- === Pestañas (Navegación y Gestión) — estilo Warp: Cmd+T nueva, Cmd+1..9 ir, Cmd+Shift+[ / ] prev/next ===
  { key = 't', mods = 'CMD', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'LeftArrow', mods = 'CMD|ALT', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CMD|ALT', action = act.ActivateTabRelative(1) },
  { key = 'LeftArrow', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'w', mods = 'LEADER', action = act.ShowTabNavigator },
  { key = '<', mods = 'LEADER|SHIFT', action = act.MoveTabRelative(-1) },
  { key = '>', mods = 'LEADER|SHIFT', action = act.MoveTabRelative(1) },
  {
    key = ',',
    mods = 'LEADER',
    action = act.PromptInputLine {
      description = 'Renombrar pestaña (vacío = volver al automático):',
      action = wezterm.action_callback(function(window, _, line)
        if line ~= nil then
          window:mux_window():active_tab():set_title(line)
        end
      end),
    },
  },

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
  { key = 'y', mods = 'LEADER', action = act.SendString '\x1by' },
  { key = 'Y', mods = 'LEADER|SHIFT', action = act.SendString 'cpout\n' },
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
