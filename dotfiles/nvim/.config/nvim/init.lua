vim.g.mapleader = " "

-- enable line numbers
vim.opt.number = true
-- use spaces instead of tabs
vim.opt.expandtab = true

-- enable spell checking for UK and US English
vim.opt.spell = true
vim.opt.spelllang = { "en_us", "en_gb" }

-- make a <Tab> counts as 3 spaces
vim.opt.tabstop = 3
vim.opt.softtabstop = 3
vim.opt.shiftwidth = 3

-- download and set catppuccin mocha theme
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
