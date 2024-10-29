return {
   "iamcco/markdown-preview.nvim",
   cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
   ft = { "markdown" },
   build = function()
      vim.fn["mkdp#util#install"]()
   end,
   config = function()
      -- Automatically start preview when opening a Markdown file
      vim.g.mkdp_auto_start = 1
      -- Automatically close the preview when leaving the Markdown buffer
      vim.g.mkdp_auto_close = 1
      -- Set the default theme for the preview (light or dark)
      vim.g.mkdp_theme = "dark"
   end,
}
