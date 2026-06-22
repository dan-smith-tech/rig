vim.g.mapleader = " "

-- enable line numbers
vim.opt.number = true
-- use spaces instead of tabs
vim.opt.expandtab = true

-- soft wrap at word boundaries (matches zed soft_wrap: "editor_width")
vim.opt.wrap = true
vim.opt.linebreak = true

-- make a <Tab> count as 4 spaces (matches zed default tab_size: 4)
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

-- ctrl+c copies, ctrl+v pastes
vim.keymap.set("v", "<C-c>", '"+y', { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "<C-v>", '"+p', { noremap = true, silent = true })
vim.keymap.set("i", "<C-v>", '<C-r>+', { noremap = true, silent = true })

-- install catppuccin theme if not already installed and set it as the colorscheme
local catpath = vim.fn.stdpath("data") .. "/site/pack/plugins/start/catppuccin"
if not vim.uv.fs_stat(catpath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/catppuccin/nvim",
        catpath,
    })
    vim.cmd("packadd catppuccin")
end
require("catppuccin").setup({ flavour = "mocha" })
vim.cmd.colorscheme("catppuccin")
