return {
	"williamboman/mason.nvim",
	config = function()
		require("mason").setup({
			ui = {
				check_outdated_packages_on_open = true,

				---@since 1.0.0
				-- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
				border = "rounded",

				---@since 1.0.0
				-- Width of the window. Accepts:
				-- - Integer greater than 1 for fixed width.
				-- - Float in the range of 0-1 for a percentage of screen width.
				width = 0.6,

				---@since 1.0.0
				-- Height of the window. Accepts:
				-- - Integer greater than 1 for fixed height.
				-- - Float in the range of 0-1 for a percentage of screen height.
				height = 0.6,

				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})
		vim.keymap.set("n", "<leader>m", "<cmd>Mason<CR>", { desc = "Mason" })
	end,
}
