return {
	"ThePrimeagen/refactoring.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		-- required on Neovim 0.12 (vim.async only exists in 0.13+)
		"lewis6991/async.nvim",
	},
  -- stylua: ignore
	keys = {
		{ "<leader>e", desc = "Refactoring" },
		{ "<leader>ev", function() return require("refactoring").extract_var() end, mode = { "n", "x" }, expr = true, desc = "Extract Variable" },
		{ "<leader>em", function() return require("refactoring").extract_func() end, mode = { "n", "x" }, expr = true, desc = "Extract Method" },
		{ "<leader>rr", function() return require("refactoring").select_refactor() end, mode = { "n", "x" }, desc = "Refactoring Menu" },
	},
	ft = { "python", "go" }, -- Load the plugin only on Python files
	config = function()
		require("refactoring").setup()
	end,
}
