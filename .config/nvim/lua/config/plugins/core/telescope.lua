return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
			require("telescope").setup({
				extensions = {
					fzf = {},
				},
			})
			require("telescope").load_extension("fzf")
			vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "Find files" })
			vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers, { desc = "Find buffers" })
			vim.keymap.set(
				"n",
				"<leader>fs",
				require("telescope.builtin").lsp_document_symbols,
				{ desc = "Find lsp symbols" }
			)
			vim.keymap.set("n", "<leader>fo", require("telescope.builtin").oldfiles, { desc = "Find recent files" })
			vim.keymap.set("n", "<leader>fs", require("telescope.builtin").grep_string, { desc = "Find string" })
			vim.keymap.set("n", "<leader>fc", function()
				require("telescope.builtin").find_files({
					cwd = vim.fn.expand("~/.config"),
				})
			end, { desc = "Find config files" })
			require("config.telescope.multigrep").setup()
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			require("telescope").load_extension("ui-select")
		end,
	},
}
