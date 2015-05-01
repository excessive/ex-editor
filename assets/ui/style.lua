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
		background_color = { 50, 60, 90, 200 },
		padding = 5,
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
}
