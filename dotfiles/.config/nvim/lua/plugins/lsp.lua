return {
   {
      "williamboman/mason.nvim",
      config = function()
         require("mason").setup()
      end,
   },
   {
      "williamboman/mason-lspconfig.nvim",
      config = function()
         require("mason-lspconfig").setup({
            ensure_installed = {
               -- C/C++
               "clangd",

               -- Web
               "html",
               "cssls",
               "ts_ls",
               "eslint",

               -- Lua
               "lua_ls",

               -- JSON
               "jsonls",

               -- YAML
               "yamlls",

               -- TOML
               "taplo",
            },
         })
      end,
   },
   {
      "neovim/nvim-lspconfig",
      config = function()
         local lspconfig = require("lspconfig")
         local capabilities = require("cmp_nvim_lsp").default_capabilities()

         -- C/C++
         lspconfig.clangd.setup({ capabilities = capabilities })

         -- Rust
         lspconfig.rust_analyzer.setup({
            capabilities = capabilities,
            settings = {
               ["rust-analyzer"] = {
                  check = {
                     command = "clippy",
                  },
                  diagnostics = {
                     enable = true,
                  },
               },
            },
            on_attach = function()
               vim.api.nvim_create_autocmd("BufWritePre", {
                  callback = function()
                     vim.lsp.buf.format({ async = false })
                  end,
               })
            end,
         })

         -- Web
         lspconfig.html.setup({ capabilities = capabilities })
         lspconfig.cssls.setup({ capabilities = capabilities })
         lspconfig.ts_ls.setup({ capabilities = capabilities })
         lspconfig.eslint.setup({ capabilities = capabilities })

         -- Lua
         lspconfig.lua_ls.setup({
            capabilities = capabilities,
            settings = {
               Lua = {
                  runtime = { version = "LuaJIT" },
                  workspace = { library = vim.api.nvim_get_runtime_file("", true) },
                  diagnostics = { globals = { "vim" } },
               },
            },
         })

         -- JSON & Markup
         lspconfig.jsonls.setup({ capabilities = capabilities })
         lspconfig.yamlls.setup({ capabilities = capabilities })
         lspconfig.taplo.setup({ capabilities = capabilities }) -- TOML

         -- Keybindings
         vim.keymap.set("n", "<leader>h", vim.lsp.buf.hover, {})
         vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, {})
         vim.keymap.set("n", "<leader>g", function()
            require("telescope.builtin").diagnostics()
         end, { desc = "Telescope workspace diagnostics" })
         vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, {})
         vim.keymap.set("n", "<leader>d", function()
            vim.cmd("leftabove vsplit")
            vim.lsp.buf.definition()
         end, {})
      end,
   },
   {
      "jay-babu/mason-null-ls.nvim",
      config = function()
         require("mason-null-ls").setup({
            ensure_installed = {
               -- C/C++
               "clang-format",

               -- YAML
               "yamllint",

               -- Lua
               "stylua",

               -- Web / Markdown / JSON / YAML
               "prettier",
            },
         })
      end,
   },
   {
      "nvimtools/none-ls.nvim",
      dependencies = {
         "nvimtools/none-ls-extras.nvim",
      },
      config = function()
         local null_ls = require("null-ls")
         local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

         null_ls.setup({
            sources = {
               -- C++
               null_ls.builtins.formatting.clang_format.with({
                  extra_args = {
                     "--style={ ContinuationIndentWidth: 3, IndentCaseLabels: true, IndentWidth: 3, IndentPPDirectives: AfterHash, PointerAlignment: Left, UseTab: Never }",
                  },
               }),

               -- Lua
               null_ls.builtins.formatting.stylua,

               -- YAML
               null_ls.builtins.diagnostics.yamllint,

               -- JSON, Markdown, YAML, HTML
               null_ls.builtins.formatting.prettier,
            },
            on_attach = function(client, bufnr)
               if client.supports_method("textDocument/formatting") then
                  vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
                  vim.api.nvim_create_autocmd("BufWritePre", {
                     group = augroup,
                     buffer = bufnr,
                     callback = function()
                        vim.lsp.buf.format()
                     end,
                  })
               end
            end,
         })
      end,
   },
}
