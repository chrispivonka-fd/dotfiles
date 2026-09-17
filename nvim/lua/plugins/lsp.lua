-- =============================================================================
-- LSP, completion (blink.cmp), and formatting
-- =============================================================================

return {
    -- Mason — LSP server installer
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        opts = {
            ui = { border = "rounded" },
        },
    },

    -- Bridge between mason and lspconfig
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            ensure_installed = {
                "lua_ls",
                "pyright",
                "ts_ls",
                "eslint",
                "bashls",
                "jsonls",
                "yamlls",
                "html",
                "cssls",
                "dockerls",
                "gopls",
                "rust_analyzer",
                "taplo",        -- TOML
            },
            automatic_enable = true,
        },
    },

    -- mason-tool-installer: ensure formatters/linters are installed
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            ensure_installed = {
                "prettier",     -- JS/TS/CSS/HTML/JSON/YAML/Markdown
                "black",        -- Python formatter
                "isort",        -- Python import sorter
                "stylua",       -- Lua formatter
                "goimports",    -- Go import organizer + formatter
                "taplo",        -- TOML formatter
            },
        },
    },

    -- conform.nvim — lightweight formatter (format-on-save)
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>cf",
                function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
                desc = "Format buffer",
            },
        },
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "isort", "black" },
                javascript = { "prettier" },
                javascriptreact = { "prettier" },
                typescript = { "prettier" },
                typescriptreact = { "prettier" },
                css = { "prettier" },
                html = { "prettier" },
                json = { "prettier" },
                yaml = { "prettier" },
                markdown = { "prettier" },
                go = { "goimports" },
                toml = { "taplo" },
            },
            format_on_save = {
                timeout_ms = 500,
                lsp_format = "fallback",
            },
        },
    },

    -- blink.cmp — fast, Rust-powered completion (replaces nvim-cmp stack)
    {
        "saghen/blink.cmp",
        dependencies = { "rafamadriz/friendly-snippets" },
        version = "*",
        opts = {
            keymap = { preset = "default" },
            appearance = {
                nerd_font_variant = "mono",
            },
            sources = {
                default = { "lazydev", "lsp", "path", "snippets", "buffer" },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100,
                    },
                },
            },
            signature = { enabled = true },
            completion = {
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 200,
                    window = { border = "rounded" },
                },
                menu = {
                    border = "rounded",
                },
            },
        },
    },

    -- LSP configuration
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "saghen/blink.cmp",
        },
        config = function()
            -- blink.cmp provides enhanced capabilities (replaces cmp-nvim-lsp)
            local capabilities = require("blink.cmp").get_lsp_capabilities()

            -- Keymaps set when LSP attaches to a buffer
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
                callback = function(event)
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
                    end

                    map("gd", vim.lsp.buf.definition, "Go to definition")
                    map("gr", vim.lsp.buf.references, "References")
                    map("gi", vim.lsp.buf.implementation, "Implementation")
                    map("K", vim.lsp.buf.hover, "Hover docs")
                    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
                    map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
                    map("<leader>D", vim.lsp.buf.type_definition, "Type definition")
                    map("<leader>ds", vim.lsp.buf.document_symbol, "Document symbols")
                    map("<leader>ws", vim.lsp.buf.workspace_symbol, "Workspace symbols")
                end,
            })

            -- Diagnostic display settings
            vim.diagnostic.config({
                virtual_text = { spacing = 4, prefix = "●" },
                signs = true,
                underline = true,
                update_in_insert = false,
                severity_sort = true,
                float = { border = "rounded" },
            })

            -- Apply capabilities to every server. mason-lspconfig.nvim's
            -- automatic_enable = true (see above) calls vim.lsp.enable() for each
            -- ensure_installed server, which merges in these vim.lsp.config()
            -- overrides — no manual lspconfig[server].setup() loop needed.
            vim.lsp.config("*", { capabilities = capabilities })

            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                        diagnostics = { globals = { "vim" } },
                    },
                },
            })
        end,
    },
}
