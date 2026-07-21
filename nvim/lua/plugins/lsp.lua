-- =============================================================================
-- LSP, completion, and formatting
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
                "basedpyright",
                "ruff",
                "vtsls",
                "bashls",
                "jsonls",
                "yamlls",
                "html",
                "cssls",
                "dockerls",
                "gopls",
                "rust_analyzer",
            },
            automatic_installation = true,
        },
    },

    -- LSP configuration
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local lspconfig = require("lspconfig")
            local cmp_lsp = require("cmp_nvim_lsp")

            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_lsp.default_capabilities()
            )

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
                    map("<leader>cl", vim.lsp.codelens.run, "CodeLens run")
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

            -- Setup each server
            local servers = {
                lua_ls = {
                    settings = {
                        Lua = {
                            workspace = { checkThirdParty = false },
                            telemetry = { enable = false },
                            diagnostics = { globals = { "vim" } },
                        },
                    },
                },
                basedpyright = {
                    settings = {
                        basedpyright = {
                            analysis = {
                                typeCheckingMode = "basic",
                                autoSearchPaths = true,
                                useLibraryCodeForTypes = true,
                            },
                        },
                    },
                },
                ruff = {},
                vtsls = {
                    settings = {
                        typescript = {
                            updateImportsOnFileMove = { enabled = "always" },
                            inlayHints = {
                                parameterNames = { enabled = "all" },
                                parameterTypes = { enabled = true },
                                variableTypes = { enabled = true },
                                propertyDeclarationTypes = { enabled = true },
                                functionLikeReturnTypes = { enabled = true },
                                enumMemberValues = { enabled = true },
                            },
                        },
                    },
                },
                bashls = {},
                jsonls = {},
                yamlls = {},
                html = {},
                cssls = {},
                dockerls = {},
                gopls = {
                    settings = {
                        gopls = {
                            analyses = { unusedparams = true },
                            staticcheck = true,
                            gofumpt = true,
                        },
                    },
                },
                rust_analyzer = {
                    settings = {
                        ["rust-analyzer"] = {
                            checkOnSave = { command = "clippy" },
                            cargo = { allFeatures = true },
                            procMacro = { enable = true },
                        },
                    },
                },
            }

            for server, config in pairs(servers) do
                config.capabilities = capabilities
                lspconfig[server].setup(config)
            end
        end,
    },

    -- Better formatting
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>f",
                function()
                    require("conform").format({ async = true, lsp_fallback = true })
                end,
                mode = "",
                desc = "Format buffer",
            },
        },
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "ruff_format", "ruff_organize_imports" },
                javascript = { "prettierd", "prettier", stop_after_first = true },
                typescript = { "prettierd", "prettier", stop_after_first = true },
                javascriptreact = { "prettierd", "prettier", stop_after_first = true },
                typescriptreact = { "prettierd", "prettier", stop_after_first = true },
                json = { "prettierd", "prettier", stop_after_first = true },
                yaml = { "prettierd", "prettier", stop_after_first = true },
                markdown = { "prettierd", "prettier", stop_after_first = true },
                rust = { "rustfmt" },
                go = { "goimports", "gofumpt" },
            },
            format_on_save = { timeout_ms = 500, lsp_fallback = true },
        },
    },

    -- Autocompletion
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "path" },
                }, {
                    { name = "buffer" },
                }),
            })
        end,
    },
}
