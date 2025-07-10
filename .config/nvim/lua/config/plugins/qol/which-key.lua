return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 3000
	end,
	opts = {
		preset = "modern",
		icons = {
			-- set to false to disable all mapping icons,
			-- both those explicitly added in a mapping
			-- and those from rules
			mappings = false,
		},
	},
}
