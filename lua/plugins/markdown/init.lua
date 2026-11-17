return {
  -- Browser-based markdown preview (kept for rendering/exporting in a real browser)
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function(plugin)
      if vim.fn.executable("npx") == 1 then
        -- npx is a .cmd wrapper on Windows, not a directly spawnable executable.
        local command = vim.fn.has("win32") == 1
          and { vim.env.ComSpec or "cmd.exe", "/d", "/s", "/c", "npx --yes yarn install" }
          or { "npx", "--yes", "yarn", "install" }
        local result = vim.system(command, {
          cwd = plugin.dir .. "/app",
          text = true,
        }):wait()
        assert(result.code == 0, result.stderr or "Markdown preview build failed")
      else
        vim.cmd [[Lazy load markdown-preview.nvim]]
        vim.fn["mkdp#util#install"]()
      end
    end,
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
  },

  -- In-editor markdown/HTML/LaTeX/Typst/YAML previewer
  {
    "OXY2DEV/markview.nvim",
    -- Do NOT lazy load: the plugin already lazy-loads itself internally.
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      -- Needed for `preview.icon_provider = "devicons"` (already installed via lualine)
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local presets = require("markview.presets")

      require("markview").setup({
        preview = {
          icon_provider = "devicons",
        },
        markdown = {
          headings = presets.headings.glow,
          tables = presets.tables.rounded,
        },
        markdown_inline = {
          enable = true,
        },
      })
    end,
  },
}
