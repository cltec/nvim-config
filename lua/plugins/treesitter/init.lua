-- return {
-- 	"nvim-treesitter/nvim-treesitter",
--     branch = "main",
-- 	build = ":TSUpdate",
-- 	config = function()
-- 		local configs = require("nvim-treesitter.configs")
--
-- 		configs.setup({
-- 			highlight = { enable = true },
-- 			ensure_installed = {
-- 				"python",
-- 				"java",
-- 				"lua",
-- 				"vim",
-- 				"vimdoc",
-- 				"query",
-- 				"go",
-- 				"gomod",
-- 				"gowork",
-- 				"gosum",
-- 			},
-- 			auto_install = true,
-- 		})
-- 	end,
-- }
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")

    local parsers = {
      "python",
      "java",
      "lua",
      "vim",
      "vimdoc",
      "query",
      "go",
      "gomod",
      "gowork",
      "gosum",
      "markdown",
      "markdown_inline",
      "yaml", -- CodeCompanion chat metadata
    }

    ts.setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    ts.install(parsers)

    local group = vim.api.nvim_create_augroup("treesitter_start", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = parsers,
      callback = function(args)
        -- Parsers install asynchronously on a fresh machine.
        if pcall(vim.treesitter.start, args.buf) then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
