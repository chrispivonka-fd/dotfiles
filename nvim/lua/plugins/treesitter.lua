-- =============================================================================
-- Treesitter — syntax highlighting, indentation, text objects
-- Note: incremental selection is no longer configured here — Neovim 0.12+
-- ships it natively (see :h treesitter-incremental-selection): "an"/"in" to
-- select/shrink to a node, "]n"/"[n" to jump between nodes, in Visual and
-- Operator-pending mode. No plugin or keymap needed.
-- =============================================================================

local ensure_installed = {
    "bash",
    "c",
    "c_sharp",
    "css",
    "dockerfile",
    "go",
    "html",
    "javascript",
    "json",
    "lua",
    "markdown",
    "markdown_inline",
    "python",
    "rust",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
}

return {
    -- nvim-treesitter's post-rewrite `main` branch dropped lazy-loading support
    -- and the old `nvim-treesitter.configs` setup API — see its README.
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local ts = require("nvim-treesitter")
            ts.setup({})

            local installed = ts.get_installed("parsers")
            local missing = vim.tbl_filter(function(lang)
                return not vim.tbl_contains(installed, lang)
            end, ensure_installed)
            if #missing > 0 then
                ts.install(missing)
            end

            -- Highlighting/indent/folding are opt-in per buffer now (nothing is
            -- enabled by default). Turn them on for any filetype with an
            -- available parser, installing it first if needed — this replaces
            -- the old `auto_install` option.
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    local lang = vim.treesitter.language.get_lang(args.match) or args.match
                    if not vim.tbl_contains(ts.get_available(), lang) then
                        return
                    end
                    if not vim.tbl_contains(ts.get_installed("parsers"), lang) then
                        ts.install(lang):wait(30000)
                    end

                    vim.treesitter.start(args.buf, lang)
                    -- foldexpr is already set globally in options.lua
                    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })
        end,
    },

    -- Syntax-aware text objects: af/if (function), ac/ic (class), aa/ia
    -- (parameter), and ]f/[f, ]c/[c to jump between them.
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        event = { "BufReadPre", "BufNewFile" },
        init = function()
            -- Avoid conflicts with Neovim's built-in ftplugin text-object maps
            vim.g.no_plugin_maps = true
        end,
        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = { lookahead = true },
                move = { set_jumps = true },
            })

            local select = require("nvim-treesitter-textobjects.select")
            local move = require("nvim-treesitter-textobjects.move")
            local map = vim.keymap.set

            map({ "x", "o" }, "af", function() select.select_textobject("@function.outer", "textobjects") end,
                { desc = "Select around function" })
            map({ "x", "o" }, "if", function() select.select_textobject("@function.inner", "textobjects") end,
                { desc = "Select inner function" })
            map({ "x", "o" }, "ac", function() select.select_textobject("@class.outer", "textobjects") end,
                { desc = "Select around class" })
            map({ "x", "o" }, "ic", function() select.select_textobject("@class.inner", "textobjects") end,
                { desc = "Select inner class" })
            map({ "x", "o" }, "aa", function() select.select_textobject("@parameter.outer", "textobjects") end,
                { desc = "Select around parameter" })
            map({ "x", "o" }, "ia", function() select.select_textobject("@parameter.inner", "textobjects") end,
                { desc = "Select inner parameter" })

            map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end,
                { desc = "Next function" })
            map({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer", "textobjects") end,
                { desc = "Next class" })
            map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end,
                { desc = "Previous function" })
            map({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end,
                { desc = "Previous class" })
        end,
    },
}
