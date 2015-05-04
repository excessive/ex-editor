local colors = {
	border     = { 50, 60, 150, 180 },
	background = { 30, 30, 50, 250 },
	heading    = mul({ 200, 220, 255, 255 }, 0.5),
	button     = { 255, 255, 255, 255 },
	text       = { 230, 230, 230, 255 },
}

local fonts = {
	normal = "assets/fonts/Homenaje/HomenajeMod-Regular.otf"
}

return {
	{ "block", {
		background_color = { 50, 60, 90, 200 },
	}},

	{ "button", {
		background_color = { 0, 0, 0, 150 },
		padding   = 5,
		font_path = "assets/fonts/Homenaje/HomenajeMod-Regular.otf",
		font_size = 18,
		cursor = "hand",
	}},

	{ "button:hover", "button.active", {
		background_color = { 0xff, 0xa8, 0x00, 200 },
		text_color = { 0xff, 0xfd, 0xfa, 255 },
	}},

	{ "#file_browser", {
		visible = false,
		-- padding = 5,
		-- width   = 300,
	}},

	{ "#file_browser block", {
		background_color = { 255, 255, 255, 0 },
	}},

	{ "#file_browser button", {
		display = "block"
	}},

	{ "#toolbar", {
		position = "absolute",
		left = 0,
		top = 0,
	}},

	{ "#toolbar button", {
		width = 100,
		margin_right = 2,
	}},

	{ "#file_menu", "#asset_menu", {
		--visible = false,
		width = 150,
		position = "absolute",
	}},

	{ "#file_menu button", "#asset_menu button", {
		width = 150,
	}},

	-- window styles
	{ ".window", {
		background_path  = "assets/ui/images/window-inactive.9.png",
		margin           = 15,
		padding          = 4,
		width            = 350,
		height           = 400,
		font_size        = 18,
		position         = "absolute",
	}},

	{ ".window.active", {
		background_path  = "assets/ui/images/window-active.9.png",
	}},

	{ ".window_content text", {
		text_color = colors.text,
		text_align = "justify",
		margin     = 10,
	}},

	{ ".window_controls", {
		position = "relative",
		height   = 30,
		-- background_color = mul(colors.background, 2.0),
	}},

	{ ".window_title", {
		position   = "absolute",
		font_path  = fonts.normal,
		font_size  = 18,
		text_align = "center",
		line_height = 1.5,
	}},

	{ ".window_close", {
		background_color = "none",
		position    = "absolute",
		right       = 0,
		top         = 0,
		width       = 30,
		height      = 30,
		text_align  = "center",
		font_size   = 14,
		line_height = 2,
		padding     = 0,
	}},

	{ ".window_close:hover", {
		background_color = { 0xff, 0xa8, 0x00, 200 },
	}},

	{ ".window_title", {
		-- text_transform = "uppercase",
		-- text_color     = mul(colors.heading, 2.5),
		-- text_shadow    = { 0, 2 },
		-- text_shadow_color = mul(colors.heading, 0.75),
		-- border_color   = mul(colors.heading, 0.65),
		-- ahahahahahaha oh wow
		-- fite me land0n
		-- margin         = { -10, -10, 2, -10 },
		-- padding        = { 15, 20, 8, 20 },
	}},

	{ ".window_content", {
		height            = 350,
		font_path         = "inherit",
		font_size         = "inherit",
		line_height       = "inherit",
		text_align        = "inherit",
		text_shadow       = "inherit",
		text_color        = "inherit",
		text_shadow_color = "inherit",
		overflow          = "scroll",
	}},

	-- file browser
	{ ".file_browser", {
		top              = 250,
		left             = 250,
	}},

	{ ".file_browser_title", {
		text_color  = { 255, 255, 255, 255 },
		text_shadow = { 2, 2 },
		font_size   = 18,
		visible     = false,
	}},

	{ ".file_browser_list", {
		text_color  = { 255, 255, 255, 255 },
		text_shadow = { 1, 1 },
		font_size   = 14,
	}},
}
