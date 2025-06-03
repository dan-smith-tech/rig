vim.g.mapleader = " "

-- Enable line numbers
vim.opt.number = true
-- Use spaces instead of tabs
vim.opt.expandtab = true

-- Enable spell checking for UK and US English
vim.opt.spell = true
vim.opt.spelllang = { "en_us", "en_gb" }

-- A <Tab> counts as 3 spaces
vim.opt.tabstop = 3
vim.opt.softtabstop = 3
vim.opt.shiftwidth = 3

-- Move left and right between windows using Ctrl + h and Ctrl + l
vim.api.nvim_set_keymap("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })
-- Move up and down between windows using Ctrl + j and Ctrl + k
vim.api.nvim_set_keymap("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })

-- Disable settings in terminal windows
vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "*",
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.spell = false
	end,
})

-- If Lazy (package manager) has not been cloned, clone it
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Setup Lazy to load plugins from each of the individual lua/plugins/<plugin>.lua files
require("lazy").setup("plugins")
