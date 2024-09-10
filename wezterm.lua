local wezterm = require("wezterm")
local mux = wezterm.mux

local config = wezterm.config_builder()

config = {
	automatically_reload_config = true,
	enable_tab_bar = false,
	enable_wayland = true,
	detect_password_input = true,
	window_close_confirmation = "NeverPrompt",
	window_decorations = "RESIZE",
	color_scheme = "Oxocarbon Dark (Gogh)",

	font_size = 11.5,
	font = wezterm.font("Hasklig", { weight = "Regular", stretch = "Normal", style = "Normal" }),
	line_height = 1.0,

	-- Enable ligatures

	-- window
	window_background_opacity = 0.80,
	window_padding = {
		left = 3,
		right = 3,
		top = 4,
		bottom = 4,
	},

	-- keys bindings
	keys = {
		{
			key = "n",
			mods = "CTRL",
			action = wezterm.action.DisableDefaultAssignment,
		},
		{
			key = "p",
			mods = "CTRL",
			action = wezterm.action.DisableDefaultAssignment,
		},
	},

	-- hyperlinks
	hyperlink_rules = {
		-- Matches: a URL in parens: (URL)
		{
			regex = "\\((\\w+://\\S+)\\)",
			format = "$1",
			highlight = 1,
		},
		-- Matches: a URL in brackets: [URL]
		{
			regex = "\\[(\\w+://\\S+)\\]",
			format = "$1",
			highlight = 1,
		},
		-- Matches: a URL in curly braces: {URL}
		{
			regex = "\\{(\\w+://\\S+)\\}",
			format = "$1",
			highlight = 1,
		},
		-- Matches: a URL in angle brackets: <URL>
		{
			regex = "<(\\w+://\\S+)>",
			format = "$1",
			highlight = 1,
		},
		-- Then handle URLs not wrapped in brackets
		{
			regex = "\\b\\w+://\\S+[)/a-zA-Z0-9-]+",
			format = "$0",
		},
		-- implicit mailto link
		{
			regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
			format = "mailto:$0",
		},
	},
}

wezterm.on("update-right-status", function(window, pane)
	local cwd = pane:get_current_working_dir()
	if cwd then
		window:set_right_status(cwd)
	end
end)

wezterm.on("gui-attached", function(domain)
	-- maximize all displayed windows on startup
	local workspace = mux.get_active_workspace()
	for _, window in ipairs(mux.all_windows()) do
		if window:get_workspace() == workspace then
			window:gui_window():maximize()
		end
	end
end)

return config