return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = "horizon",
				},
				sections = {
					lualine_b = {
						{
							"filename",
							symbols = {
								unnamed = "",
							},
						},
					},
					lualine_c = {},
					lualine_x = {},
				},
			})
		end,
	},
}
