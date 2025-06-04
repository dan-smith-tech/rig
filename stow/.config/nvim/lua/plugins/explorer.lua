return {
   {
      "nvim-telescope/telescope-ui-select.nvim",
   },
   {
      "nvim-telescope/telescope.nvim",
      tag = "0.1.6",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
         local telescope = require("telescope")
         local actions = require("telescope.actions")
         telescope.setup({
            defaults = {
               hidden = true,
               no_ignore = true,
               mappings = {
                  i = {
                     ["<C-CR>"] = actions.select_vertical,
                     ["<C-x>"] = function() end,
                  },
                  n = {
                     ["<C-CR>"] = actions.select_vertical,
                     ["<C-x>"] = function() end,
                  },
               },
            },
            pickers = {
               find_files = {
                  hidden = true,
                  no_ignore = true,
               },
            },
         })
         telescope.load_extension("ui-select")
      end,
   },
   {
      "nvim-telescope/telescope-file-browser.nvim",
      dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
      config = function()
         vim.keymap.set(
            "n",
            "<C-d>",
            ":Telescope file_browser path=%:p:h select_buffer=true hidden=true no_ignore=true<CR>"
         )
         vim.keymap.set("n", "<C-f>", ":Telescope find_files hidden=true no_ignore=true<CR>")
         vim.keymap.set("n", "<C-g>", ":Telescope live_grep hidden=true<CR>")
      end,
   },
}
