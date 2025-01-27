return {
   "olimorris/codecompanion.nvim",
   dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
   },
   config = function()
      require("codecompanion").setup({
         strategies = {
            chat = {
               adapter = "anthropic",
            },
            inline = {
               adapter = "anthropic",
            },
         },
         display = {
            action_palette = {
               provider = "telescope",
            },
         },
      })

      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd([[cab cc CodeCompanion]])
      -- Expand 'ccc' into 'CodeCompanionChat Toggle' in the command line
      vim.cmd([[cab ccc CodeCompanionChat Toggle]])
      -- Expand 'cca' into 'CodeCompanionActions' in the command line
      vim.cmd([[cab cca CodeCompanionActions]])
   end,
}
