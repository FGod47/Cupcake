return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{
			"folke/lazydev.nvim",
			ft = "lua", -- only load on lua files
			opts = {
				library = {
					-- See the configuration section for more details
					-- Load luvit types when the `vim.uv` word is found
					{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				},
			},
		},
	},
	config = function()
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		-- Change the Diagnostic symbols in the sign column (gutter)
		local signs = { Error = "", Warn = "", Hint = "󰠠", Info = "" }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		require("mason-lspconfig").setup_handlers({
			-- default handler for installed servers
			function(server_name)
				require("lspconfig")[server_name].setup({
					capabilities = capabilities,
				})
			end,
		})

		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })

		vim.keymap.set("n", "<leader>gd", vim.lsp.buf.declaration, { desc = "Go to declaration" }) -- go to declaration

		vim.keymap.set("n", "<leader>co", vim.lsp.buf.rename, { desc = "Change all occurrence" }) -- smart rename

		vim.keymap.set("n", "<leader>dp", vim.diagnostic.goto_prev, { desc = "Go to prev diagnostic" }) -- jump to previous diagnostic in buffer

		vim.keymap.set("n", "<leader>dn", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" }) -- jump to next diagnostic in buffer

		vim.keymap.set("n", "<leader>lr", ":LspRestart<CR>", { desc = "Restart LSP" }) -- mapping to restart lsp if necessary

		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if not client then
					return
				end

				if client.supports_method("textDocument/formatting") then
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = args.buf,
						callback = function()
							vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
						end,
					})
				end
			end,
		})
	end,
}
