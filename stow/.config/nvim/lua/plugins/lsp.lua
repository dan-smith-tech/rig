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

					-- Rust
					"rust-analyzer",

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

			-- Python
			lspconfig.pyright.setup({
				capabilities = capabilities,

				before_init = function(_, config)
					config.settings.python.pythonPath = vim.env.VIRTUAL_ENV .. "/bin/python3"
				end,
			})

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
				on_attach = function(client, bufnr)
					-- Add format as we use `rust-analyzer` for formatting and not null-ls
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
					},
				},
			})

			-- JSON
			lspconfig.jsonls.setup({ capabilities = capabilities })

			-- YAML
			lspconfig.yamlls.setup({ capabilities = capabilities })

			-- Rust / TOML
			lspconfig.taplo.setup({ capabilities = capabilities })

			vim.keymap.set("n", "<leader>h", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, {})
			vim.keymap.set("n", "<leader>g", function()
				require("telescope.builtin").diagnostics()
			end, { desc = "Telescope workspace diagnostics" })
			vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, {})
			vim.keymap.set("n", "<leader>d", vim.lsp.buf.definition, {})
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
