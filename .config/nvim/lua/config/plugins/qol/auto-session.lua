return {
	"rmagatti/auto-session",
	lazy = false,
	config = function()
		require("auto-session").setup({
			auto_restore_enabled = false,
		})
		vim.keymap.set("n", "<leader>sr", "<cmd>SessionRestore<CR>", { desc = "Restore session" })
		vim.keymap.set("n", "<leader>ss", "<cmd>SessionSave<CR>", { desc = "Save session" })
	end,
}
