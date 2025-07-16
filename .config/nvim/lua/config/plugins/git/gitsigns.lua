return {
	"lewis6991/gitsigns.nvim",
	config = function()
		require("gitsigns").setup()

		vim.keymap.set("n", "<leader>gh", "<cmd>Gitsigns preview_hunk<CR>", { desc = "Preview git hunks" })
		vim.keymap.set("n", "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<CR>", { desc = "Toggle git blame" })
	end,
}
