return {
   "github/copilot.vim",
   -- Note: must run `:Copilot setup` after this package gets installed
   config = function()
      -- Use Shift+Tab to accept suggestions
      vim.keymap.set("i", "<S-Tab>", 'copilot#Accept("\\<CR>")', {
         expr = true,
         replace_keycodes = false,
      })
      vim.g.copilot_no_tab_map = true
   end,
}
