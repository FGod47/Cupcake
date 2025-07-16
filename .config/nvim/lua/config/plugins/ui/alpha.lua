return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- Set header
    dashboard.section.header.val = {
      "                                                     ",
      "                                                     ",
      "                                                     ",
      "                                                     ",
      "                                                     ",
      "                                                     ",
      "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
      "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
      "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
      "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
      "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
      "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
      "                                                     ",
    }

    -- Set menu
    dashboard.section.buttons.val = {
      dashboard.button("?", "?  > Help", "<cmd>WhichKey<CR>", { desc = "Help/Search backward" }),
      -- dashboard.button("SPC l", "L  > Lazy", "<cmd>Lazy<CR>", { desc = "Lazy" }),
      -- dashboard.button("SPC m", "M  > Mason", "<cmd>Mason<CR>", { desc = "Mason" }),
      dashboard.button(
        "SPC ee",
        "  > Toggle file explorer",
        "<cmd>Neotree toggle<CR>",
        { desc = "Toggle file tree" }
      ),
      dashboard.button("SPC ff", "󰱼  > Find File", "<cmd>Telescope find_files<CR>", { desc = "Find files" }),
      dashboard.button(
        "SPC sr",
        "󰁯  > Restore Session",
        "<cmd>SessionRestore<CR>",
        { desc = "Restore session" }
      ),
      dashboard.button("q", "  > Quit NVIM", "<cmd>quit<CR>", { desc = "Quit" }),
    }

    -- Send config to alpha
    alpha.setup(dashboard.opts)

    -- Disable folding on alpha buffer
    vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
  end,
}
