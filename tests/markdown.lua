-- Run from the repository root: nvim --headless -u NONE -l tests/markdown.lua
local preview = dofile("lua/plugins/markdown/init.lua")[1]
local saved = {
	executable = vim.fn.executable,
	has = vim.fn.has,
	install = vim.fn["mkdp#util#install"],
	system = vim.system,
	cmd = vim.cmd,
	filetypes = vim.g.mkdp_filetypes,
}
local windows, available, exit_code = false, true, 0
local command, options, loaded, installed
vim.fn.executable = function(name)
	assert(name == "npx")
	return available and 1 or 0
end
vim.fn.has = function(name)
	assert(name == "win32")
	return windows and 1 or 0
end
vim.system = function(cmd, opts)
	command, options = cmd, opts
	return {
		wait = function()
			return { code = exit_code, stderr = "build failed" }
		end,
	}
end
vim.cmd = function(cmd)
	loaded = cmd
end
vim.fn["mkdp#util#install"] = function()
	installed = true
end

local ok, err = xpcall(function()
	preview.init()
	assert(vim.deep_equal(vim.g.mkdp_filetypes, { "markdown" }))
	preview.build({ dir = "/a config path/markdown-preview.nvim" })
	assert(vim.deep_equal(command, { "npx", "--yes", "yarn", "install" }))
	assert(
		options.cwd == "/a config path/markdown-preview.nvim/app",
		"Paths with spaces must not use shell interpolation"
	)

	windows = true
	preview.build({ dir = "C:/Users/A Name/markdown-preview.nvim" })
	assert(command[1] == (vim.env.ComSpec or "cmd.exe"))
	assert(vim.deep_equal(vim.list_slice(command, 2), { "/d", "/s", "/c", "npx --yes yarn install" }))
	assert(options.cwd == "C:/Users/A Name/markdown-preview.nvim/app")

	exit_code = 1
	assert(not pcall(preview.build, { dir = "/test" }), "Failed builds must be reported")

	available = false
	command = nil
	preview.build({ dir = "/test" })
	assert(command == nil, "executable() returning 0 must not run npx")
	assert(loaded:match("Lazy load markdown%-preview.nvim") and installed, "Use prebuilt installer when npx is absent")
end, debug.traceback)

vim.fn.executable, vim.fn.has = saved.executable, saved.has
vim.fn["mkdp#util#install"] = saved.install
vim.system, vim.cmd = saved.system, saved.cmd
vim.g.mkdp_filetypes = saved.filetypes
assert(ok, err)
print("Markdown build tests passed (Unix, Windows, paths with spaces, missing npx, failed build)")
