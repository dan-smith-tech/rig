return {
	"akinsho/toggleterm.nvim",
	version = "*",
	opts = {
		direction = "vertical",
		size = 100,
		open_mapping = [[<C-t>]],
		shade_terminals = false,
		persist_size = false,
	},
	config = function(_, opts)
		require("toggleterm").setup(opts)

		local map_opts = { noremap = true, silent = true }

		--Toggle each of 3 terminals with Ctrl + 1, 2, or 3
		vim.keymap.set("n", "<C-1>", ":1ToggleTerm<CR>", map_opts)
		vim.keymap.set("n", "<C-2>", ":2ToggleTerm<CR>", map_opts)
		vim.keymap.set("n", "<C-3>", ":3ToggleTerm<CR>", map_opts)

		-- Exit terminal mode using Esc
		vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], map_opts)
	end,
}
