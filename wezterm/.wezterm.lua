local wezterm = require 'wezterm'
local act = wezterm.action
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

-- Plugin: bar.wezterm
local bar = wezterm.plugin.require('https://github.com/adriankarlen/bar.wezterm')
bar.apply_to_config(config, {
  position = 'bottom',
  max_width = 52,
  modules = {
    tabs = {
      active_tab_fg = 4,
      inactive_tab_fg = 6,
    },
    workspace = {
      enabled = true,
    },
    leader = {
      enabled = true,
    },
    cwd = {
      enabled = true,
    },
    hostname = {
      enabled = true,
      color = 8,
    },
    username = {
      enabled = true,
      color = 6,
    },
    spotify = {
      enabled = false,
      color = 2,
    },
    clock = {
      enabled = true,
      format = '%H:%M',
    },
  },
})

----------------------------------------------------
-- 6. ATAJOS DE TECLADO (Unificados)
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

  -- === Pestañas ===
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
  -- Guardar estado actual
  {
    key = 'S',
    mods = 'LEADER|SHIFT',
    action = wezterm.action_callback(function(_, _)
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
    end),
  },
  -- Restaurar estado guardado con selector difuso
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

return config
