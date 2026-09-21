-- =============================================================================
-- snacks.nvim — Folke's all-in-one utility collection
-- Replaces: telescope (picker), indent-blankline (indent), bigfile, notifier,
--           lazygit integration, terminal, gitbrowse, words highlight,
--           neo-tree (file explorer), etc.
-- =============================================================================

return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            -- Start screen
            dashboard = { enabled = true },

            -- Status column (replaces statuscolumn hand-rolling)
            statuscolumn = { enabled = true },

            -- File explorer (replaces neo-tree.nvim)
            explorer = {},

            -- Fuzzy picker (replaces telescope)
            picker = {
                sources = {
                    explorer = {
                        hidden = true, -- show dotfiles
                        exclude = { ".git", "node_modules", ".DS_Store" },
                    },
                },
                win = {
                    input = {
                        keys = {
                            ["<C-j>"] = { "list_down", mode = { "i", "n" } },
                            ["<C-k>"] = { "list_up",   mode = { "i", "n" } },
                            ["<C-q>"] = { "qflist",    mode = { "i", "n" } },
                        },
                    },
                },
            },

            -- Indent guides (replaces indent-blankline.nvim)
            indent = {
                enabled = true,
                indent = { char = "│" },
                scope = { enabled = true, show_start = false, show_end = false },
            },

            -- Disable heavy features when opening very large files
            bigfile = { enabled = true },

            -- Pretty notifications (replaces nvim-notify)
            notifier = {
                enabled = true,
                timeout = 3000,
            },

            -- Floating lazygit
            lazygit = { enabled = true },

            -- Floating terminal
            terminal = { enabled = true },

            -- Open file/line in GitHub/GitLab
            gitbrowse = { enabled = true },

            -- Highlight current word under cursor
            words = { enabled = true },

            -- Better vim.ui.input
            input = { enabled = true },

            -- Smooth scrolling
            scroll = { enabled = false }, -- can cause issues in some terminals; opt-in

            -- zen mode
            zen = { enabled = true },
        },
        keys = {
            -- File explorer (same layout as previous neo-tree keymaps)
            { "<leader>e", function() Snacks.explorer.open() end,                desc = "Toggle file explorer" },
            { "<leader>E", function() Snacks.explorer.reveal() end,              desc = "Reveal current file" },
            -- Picker keymaps (same layout as previous telescope)
            { "<leader>ff", function() Snacks.picker.files() end,                desc = "Find files" },
            { "<leader>fg", function() Snacks.picker.grep() end,                 desc = "Live grep" },
            { "<leader>fb", function() Snacks.picker.buffers() end,              desc = "Buffers" },
            { "<leader>fh", function() Snacks.picker.help() end,                 desc = "Help tags" },
            { "<leader>fr", function() Snacks.picker.recent() end,               desc = "Recent files" },
            { "<leader>fd", function() Snacks.picker.diagnostics() end,          desc = "Diagnostics" },
            { "<leader>fs", function() Snacks.picker.git_status() end,           desc = "Git status" },
            { "<leader>fc", function() Snacks.picker.git_log() end,              desc = "Git commits" },
            { "<leader>/",  function() Snacks.picker.lines() end,                desc = "Search in buffer" },
            { "<leader>fw", function() Snacks.picker.grep_word() end,            desc = "Search word under cursor" },
            { "<leader>fk", function() Snacks.picker.keymaps() end,              desc = "Keymaps" },
            { "<leader>fp", function() Snacks.picker.projects() end,             desc = "Projects" },
            -- Git
            { "<leader>gg", function() Snacks.lazygit() end,                     desc = "Lazygit" },
            { "<leader>gB", function() Snacks.gitbrowse() end,                   desc = "Open in GitHub" },
            -- Terminal
            { "<leader>tt", function() Snacks.terminal() end,                    desc = "Toggle terminal" },
            -- Zen
            { "<leader>tz", function() Snacks.zen() end,                         desc = "Toggle zen mode" },
            -- Notifications
            { "<leader>n",  function() Snacks.notifier.show_history() end,       desc = "Notification History" },
            { "<leader>un", function() Snacks.notifier.hide() end,               desc = "Dismiss All Notifications" },
        },
    },
}
