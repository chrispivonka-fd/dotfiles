-- =============================================================================
-- Key mappings
-- =============================================================================

local map = vim.keymap.set

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to below split" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to above split" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

-- Buffer navigation
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Better indenting (keep selection)
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Move lines up/down
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- Quick save / quit
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Force quit all" })

-- Diagnostic navigation
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- Better paste (don't overwrite register)
map("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Center screen after jumps
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down + center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up + center" })
map("n", "n", "nzzzv", { desc = "Next search + center" })
map("n", "N", "Nzzzv", { desc = "Prev search + center" })

-- Window resizing
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- Escape shortcut (home-row friendly): see better-escape.nvim in plugins/editor.lua

-- Select all (visual)
map("n", "<leader>va", "ggVG", { desc = "Select all" })
