-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
	ui = {
		-- a number <1 is a percentage., >1 is a fixed size
		size = { width = 0.6, height = 0.6 },
		-- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
		border = "rounded",
	},
	spec = {
		-- import your plugins
		{ import = "config.plugins.auto-completion" },
		{ import = "config.plugins.core" },
		{ import = "config.plugins.git" },
		{ import = "config.plugins.lsp" },
		{ import = "config.plugins.qol" },
		{ import = "config.plugins.ui" },
	},
	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = { colorscheme = { "catppuccin" } },
	-- automatically check for plugin updates
	checker = { enabled = true },
})

vim.keymap.set("n", "<leader>l", "<cmd>Lazy<CR>", { desc = "Lazy" })
