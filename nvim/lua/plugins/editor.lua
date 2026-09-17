-- =============================================================================
-- Editor utilities: autopairs, which-key, flash, etc.
-- Note: comment toggling (gcc/gc) is native in Neovim 0.10+ via vim.comment
-- File explorer: snacks.nvim's built-in explorer, see plugins/snacks.lua
-- =============================================================================

return {
    -- Auto pairs
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },

    -- Better escape (jk to exit insert mode, without blocking on timeoutlen)
    {
        "max397574/better-escape.nvim",
        event = "InsertEnter",
        opts = {
            timeout = 200,
        },
    },

    -- Which-key (shows available keymaps)
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            spec = {
                { "<leader>f", group = "Find" },
                { "<leader>h", group = "Git hunks" },
                { "<leader>b", group = "Buffer" },
                { "<leader>c", group = "Code" },
                { "<leader>r", group = "Rename" },
                { "<leader>t", group = "Toggle" },
                { "<leader>g", group = "Git" },
            },
        },
    },

    -- Detect indent style automatically
    {
        "tpope/vim-sleuth",
        event = { "BufReadPre", "BufNewFile" },
    },

    -- Surround motions (ys, ds, cs)
    {
        "kylechui/nvim-surround",
        version = "*",
        event = "VeryLazy",
        config = true,
    },

    -- Flash: fast cursor jump with s/S (replaces leap/hop)
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {
            modes = {
                search = { enabled = false }, -- don't hijack / search
                char = { enabled = true },    -- enhance f/t/F/T
            },
        },
        keys = {
            { "s",     function() require("flash").jump() end,              mode = { "n", "x", "o" }, desc = "Flash jump" },
            { "S",     function() require("flash").treesitter() end,        mode = { "n", "x", "o" }, desc = "Flash treesitter" },
            { "r",     function() require("flash").remote() end,            mode = "o",               desc = "Remote flash" },
            { "R",     function() require("flash").treesitter_search() end, mode = { "o", "x" },      desc = "Treesitter search" },
            { "<C-s>", function() require("flash").toggle() end,            mode = "c",               desc = "Toggle flash search" },
        },
    },

    -- lazydev: faster Lua LSP for Neovim config/plugin development
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },

    -- Todo comments highlighting
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        event = { "BufReadPre", "BufNewFile" },
        opts = {},
        keys = {
            { "<leader>ft", function() Snacks.picker.todo_comments() end, desc = "Find TODOs" },
        },
    },
}
