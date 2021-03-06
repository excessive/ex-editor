return {
	{ "block", id="toolbar",
		{ "button", value="File",  id="file_button", open="file_menu" },
		{ "button", value="Asset", id="asset_button", open="asset_menu" },
	},
	{ "inline", id="file_menu", class="menu",
		-- { "button", value="Load",    id="file_load" },
		-- { "button", value="Save",    id="file_save" },
		{ "button", value="Connect Remote", id="file_connect" },
		{ "button", value="Connect Local", id="file_connect_local" },
		{ "button", value="Exit",    id="file_exit" },
	},
	{ "inline", id="asset_menu", class="menu",
		{ "button", value="List",   id="asset_list" },
		{ "button", value="Add",    id="asset_add" },
	},
	{ "file_browser", id="file_browser", title="Assets" },
}
