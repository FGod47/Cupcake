return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	config = function()
		require("nvim-autopairs").setup({
			disable_in_macro = false,
			disable_in_replace_mode = false,
		})
	end,
}
