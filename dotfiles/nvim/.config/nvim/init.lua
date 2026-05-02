vim.g.mapleader = " "

-- enable line numbers
vim.opt.number = true
-- use spaces instead of tabs
vim.opt.expandtab = true

-- enable spell checking for UK and US English
vim.opt.spell = true
vim.opt.spelllang = { "en_us", "en_gb" }

-- soft wrap at word boundaries (matches zed soft_wrap: "editor_width")
vim.opt.wrap = true
vim.opt.linebreak = true

-- make a <Tab> count as 4 spaces (matches zed default tab_size: 4)
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

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
