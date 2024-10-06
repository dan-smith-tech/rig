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
               -- Python
               "pyright",

               -- C/C++
               "clangd",

               -- Web
               "html",
               "cssls",
               "tsserver",
               "eslint",

               -- Lua
               "lua_ls",

               -- JSON
               "jsonls",

               -- YAML
               "yamlls",

               -- Rust / TOML
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

         -- Python
         lspconfig.pyright.setup({ capabilities = capabilities })

         -- C/C++
         lspconfig.clangd.setup({ capabilities = capabilities })

         -- Web
         lspconfig.html.setup({ capabilities = capabilities })
         lspconfig.cssls.setup({ capabilities = capabilities })
         lspconfig.tsserver.setup({ capabilities = capabilities })
         lspconfig.eslint.setup({ capabilities = capabilities })

         -- Lua
         lspconfig.lua_ls.setup({ capabilities = capabilities })

         -- JSON
         lspconfig.jsonls.setup({ capabilities = capabilities })

         -- YAML
         lspconfig.yamlls.setup({ capabilities = capabilities })

         -- Rust / TOML
         lspconfig.taplo.setup({ capabilities = capabilities })

         vim.keymap.set("n", "<C-w>", vim.lsp.buf.hover, {})
         vim.keymap.set("n", "<C-a>", vim.lsp.buf.code_action, {})
         vim.keymap.set("n", "<C-s>", vim.lsp.buf.definition, {})
      end,
   },
   {
      "jay-babu/mason-null-ls.nvim",
      config = function()
         require("mason-null-ls").setup({
            ensure_installed = {
               -- Python
               "pylint",
               "mypy",
               "black",
               "isort",

               -- C/C++
               "clang-format",

               -- Web
               "eslint_d",

               -- Lua
               "stylua",

               -- JSON
               "prettier",

               -- YAML
               "yamllint",

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
               -- Python
               null_ls.builtins.diagnostics.pylint,
               null_ls.builtins.diagnostics.mypy,
               null_ls.builtins.formatting.black,
               null_ls.builtins.formatting.isort,

               -- C/C++
               null_ls.builtins.formatting.clang_format.with({
                  extra_args = {
                     "--style={ ContinuationIndentWidth: 3, IndentCaseLabels: true, IndentWidth: 3, IndentPPDirectives: AfterHash, PointerAlignment: Left, UseTab: Never }",
                  },
               }),

               -- Lua
               null_ls.builtins.formatting.stylua,

               -- YAML
               null_ls.builtins.diagnostics.yamllint,

               -- Web / Markdown / JSON / YAML
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
