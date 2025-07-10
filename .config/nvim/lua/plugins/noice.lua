return {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
    },
    config = function()

        vim.api.nvim_set_hl(0, "MyBorderHighlight", { fg = "#aea7d6", bg = "NONE" })
        require('noice').setup({
            notify = {
                enabled = false,
                view = "notify",
            },
            messages = {
                enabled = false,
            },
            presets = {
                long_message_to_split = true,
            },
            cmdline = {
                enabled = true,
                view = "cmdline_popup",
                format = {},
            },
            views = {
                cmdline_popup = {
                    win_options = {
                        winhighlight = { NormalFloat = "NormalFloat", FloatBorder = "FloatBorder" },
                    },
                    position = {
                        row = 1,
                        col = "50%",
                    },
                    size = {
                        width = "50%",
                        height = 1,
                    },
                    border = {
                        style = "none",
                        padding = { 2, 3 },
                    },
                },
            },
        })
    end
}
