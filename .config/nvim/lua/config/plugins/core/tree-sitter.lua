return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
      "windwp/nvim-ts-autotag",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
        autotag = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<leader><leader>",
            node_incremental = "<leader><leader>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },
      })
      vim.keymap.set("n", "<leader>ti", "<cmd>InspectTree<CR>", { desc = "Inspect tree-sitter" })
    end,
  },
}
