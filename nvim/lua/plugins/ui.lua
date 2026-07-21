-- =============================================================================
-- UI: theme, statusline, git signs, indent guides
-- =============================================================================

return {
    -- GitHub Dark theme
    {
        "projekt0n/github-nvim-theme",
        name = "github-theme",
        priority = 1000,
        lazy = false,
        opts = {
            options = {
                transparent = false,
            },
        },
        config = function(_, opts)
            require("github-theme").setup(opts)
            vim.cmd.colorscheme("github_dark")
        end,
    },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        event = "VeryLazy",
        opts = {
            options = {
                theme = "auto",
                globalstatus = true,
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
            },
            sections = {
                lualine_a = { { "mode", fmt = function(str) return str:sub(1, 1) end } },
                lualine_b = { "branch" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "diagnostics", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        },
    },

    -- Git signs in the gutter
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            signs = {
                add = { text = "+" },
                change = { text = "~" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
            },
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns
                local map = function(mode, l, r, desc)
                    vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
                end

                map("n", "]h", gs.next_hunk, "Next hunk")
                map("n", "[h", gs.prev_hunk, "Previous hunk")
                map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
                map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
                map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
                map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
                map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
                map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
                map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle line blame")
                map("n", "<leader>hd", gs.diffthis, "Diff this")
            end,
        },
    },

    -- Snacks.nvim: A collection of small QoL plugins (Dashboard, Scroll, etc.)
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            dashboard = { enabled = true },
            indent = { enabled = true },
            input = { enabled = true },
            notifier = { enabled = true, timeout = 3000 },
            scope = { enabled = true },
            scroll = { enabled = true },
            statuscolumn = { enabled = true },
            words = { enabled = true },
        },
        keys = {
            { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification History" },
            { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
        },
    },

    -- Subtle animations (cursor, scroll, window resize)
    {
        "echasnovski/mini.animate",
        event = "VeryLazy",
        opts = {
            cursor = { enable = false },
            scroll = { enable = true },
            resize = { enable = true },
            window = { enable = true },
        },
    },

    -- Icons (dependency for many plugins)
    {
        "nvim-tree/nvim-web-devicons",
        lazy = true,
    },

    -- Better diagnostics list
    {
        "folke/trouble.nvim",
        cmd = { "Trouble" },
        opts = {
            use_diagnostic_signs = true,
            modes = {
                symbols = {
                    desc = "Symbols",
                    mode = "lsp_document_symbols",
                    focus = false,
                    win = { position = "right", width = 30 },
                },
            },
        },
        keys = {
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
            { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
            { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
            { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP Definitions / references / ... (Trouble)" },
        },
    },

    -- Highly experimental UI overhaul (Noice)
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        opts = {
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.set_autocmd_lru"] = true,
                    ["package.loaded['vim.lsp.util'].convert_input_to_markdown_lines"] = true,
                },
            },
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
            },
            views = {
                cmdline_popup = {
                    position = { row = 5, col = "50%" },
                    size = { width = 60, height = "auto" },
                },
            },
        },
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        },
    },
}
