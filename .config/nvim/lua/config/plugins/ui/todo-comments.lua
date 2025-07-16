return {
	"folke/todo-comments.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("todo-comments").setup()
		vim.keymap.set("n", "<leader>tn", function()
			require("todo-comments").jump_next()
		end, { desc = "Next todo comment" })

		vim.keymap.set("n", "<leader>tp", function()
			require("todo-comments").jump_prev()
		end, { desc = "Previous todo comment" })
	end,
}
