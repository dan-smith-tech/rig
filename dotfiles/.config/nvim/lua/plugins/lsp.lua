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
			lspconfig.pyright.setup({ capabilities = capabilities })

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
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					-- Python
					"ruff",
					"mypy",

					-- C/C++
					"clang-format",

					-- Web
					"prettier",

					-- Lua
					"stylua",

					-- YAML
					"yamllint",
				},
			})
		end,
	},
	{
		"mfussenegger/nvim-lint",
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				python = { "ruff", "mypy" },
				yaml = { "yamllint" },
			}

			-- Create autocommand for linting
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})

			vim.keymap.set("n", "<leader>l", function()
				lint.try_lint()
			end, { desc = "Trigger linting for current file" })
		end,
	},
	{
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					python = { "ruff_format", "ruff_organize_imports" },
					cpp = { "clang-format" },
					c = { "clang-format" },
					lua = { "stylua" },
					javascript = { "prettier" },
					typescript = { "prettier" },
					json = { "prettier" },
					yaml = { "prettier" },
					markdown = { "prettier" },
					html = { "prettier" },
					css = { "prettier" },
				},
				formatters = {
					["clang-format"] = {
						prepend_args = {
							"--style={ ContinuationIndentWidth: 3, IndentCaseLabels: true, IndentWidth: 3, IndentPPDirectives: AfterHash, PointerAlignment: Left, UseTab: Never }",
						},
					},
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},
			})

			vim.keymap.set({ "n", "v" }, "<leader>f", function()
				require("conform").format({
					lsp_fallback = true,
					async = false,
					timeout_ms = 500,
				})
			end, { desc = "Format file or range (in visual mode)" })
		end,
	},
}
