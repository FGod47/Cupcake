 return {
    "epwalsh/obsidian.nvim",
    version = "*",  -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",

    dependencies = {
        -- Required.
        "nvim-lua/plenary.nvim",
    },

    opts = {
        workspaces = {
            {
                name = "Deutsch-Mündlich",
                path = "~/Schule/obsidian/Deutsch-Mündlich",
            },
            {
                name = "Ethik-Mündlich",
                path = "~/Schule/obsidian/Ethik-Mündlich"
            },
        },
    },

    config = function(_, opts)
        require("obsidian").setup(opts)

        vim.keymap.set("n", "gf", function()
            if require("obsidian").util.cursor_on_markdown_link() then
                return "<cmd>ObsidianFollowLink<CR>"
            else
                return "gf"
            end
        end, { noremap = false, expr = true })
    end,
}
