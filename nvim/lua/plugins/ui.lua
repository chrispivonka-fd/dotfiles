-- =============================================================================
-- UI: theme, statusline, git signs
-- Indent guides are handled by snacks.nvim (see snacks.lua)
-- =============================================================================

return {
    -- GitHub Dark theme
    {
        "projekt0n/github-nvim-theme",
        name = "github-nvim-theme",
        priority = 1000,
        lazy = false,
        config = function()
            require("github-theme").setup({
                options = {
                    transparent = false,
                    styles = {
                        comments = "italic",
                        keywords = "bold",
                    },
                },
            })
            vim.cmd.colorscheme("github_dark_default")
        end,
    },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = {
            options = {
                theme = "auto",
                globalstatus = true,
                component_separators = { left = "|", right = "|" },
                section_separators = { left = "", right = "" },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "encoding", "fileformat", "filetype" },
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

    -- mini.icons — actively maintained replacement for nvim-web-devicons
    {
        "echasnovski/mini.icons",
        lazy = true,
        opts = {
            style = "glyph",
        },
        init = function()
            -- Provide nvim-web-devicons compatibility shim so plugins that
            -- require("nvim-web-devicons") work without a separate install
            package.preload["nvim-web-devicons"] = function()
                require("mini.icons").mock_nvim_web_devicons()
                return package.loaded["nvim-web-devicons"]
            end
        end,
    },
}
