-- Run from the repository root: nvim --headless -u NONE -l tests/typescript.lua
package.path = "./lua/?.lua;" .. package.path
local ts = require("config.typescript")
local root = vim.fn.tempname() .. " TS project"
local nested = root .. "/packages/app"
local function write(path, contents)
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	vim.fn.writefile({ contents }, path)
end
local function tool(name, bin, entry)
	write(root .. "/node_modules/" .. name .. "/package.json", vim.json.encode({ bin = bin }))
	write(root .. "/node_modules/" .. name .. "/" .. entry, "// fixture")
end
local function check(condition, message)
	assert(condition, message)
end
local saved_dap, saved_utils, saved_mason =
	package.loaded.dap, package.loaded["dap.utils"], package.loaded["mason.settings"]
local saved_stat, saved_exepath = vim.uv.fs_stat, vim.fn.exepath
local ok, err = xpcall(function()
	write(root .. "/package.json", "{}")
	root = vim.uv.fs_realpath(root)
	nested = root .. "/packages/app"
	write(nested .. "/package.json", "{}")
	write(nested .. "/src/app.ts", "const x=1")
	vim.cmd.edit(vim.fn.fnameescape(nested .. "/src/app.ts"))
	check(ts.root(nested .. "/src/app.ts") == nested, "Use the nearest workspace package")
	check(ts.formatter() == nil, "Do not fall back to global/downloaded formatters")
	tool("prettier", "bin/prettier.cjs", "bin/prettier.cjs")
	local entry = root .. "/node_modules/prettier/bin/prettier.cjs"
	check(ts.tool("prettier", "prettier", nested .. "/src/app.ts") == entry, "Find hoisted tools")
	local format = ts.formatter()
	check(format.exe == "node" and format.cwd == nested and format.stdin, "Use project cwd and stdin")
	check(format.args[1] == vim.fn.shellescape(entry), "Escape paths with spaces for formatter.nvim")
	check(format.args[2] == "--stdin-filepath", "Use Prettier")

	write(root .. "/biome.json", "{}")
	check(ts.formatter() == nil, "Do not use Prettier in a Biome project without Biome installed")
	tool("@biomejs/biome", { biome = "bin/biome" }, "bin/biome")
	format = ts.formatter()
	check(format.args[2] == "format" and format.args[3] == "--stdin-file-path", "Respect Biome")

	for _, runner in ipairs({ "vitest", "jest" }) do
		tool(runner, { [runner] = "bin/cli.js" }, "bin/cli.js")
		write(nested .. "/" .. runner .. ".config.cjs", "module.exports = {}")
		package.loaded["neotest-" .. runner] = function(options)
			check(options[runner .. "Command"] == "node", "Avoid shell/.cmd test shims")
			check(
				options[runner .. "ConfigFile"](nested .. "/src/app.ts") == nested .. "/" .. runner .. ".config.cjs",
				"Find CJS configs without Vimscript in async contexts"
			)
			return {
				build_spec = function()
					return { command = { "node", "--fixture" }, strategy = { type = "pwa-node" } }
				end,
			}
		end
		local adapter = ts.test_adapter(runner)
		check(ts.test_adapter(runner) == adapter, "Repeated setup must not wrap test commands twice")
		local spec = adapter.build_spec({
			tree = {
				data = function()
					return { path = nested .. "/src/app.ts" }
				end,
			},
			strategy = "dap",
		})
		check(spec.command[2] == root .. "/node_modules/" .. runner .. "/bin/cli.js", "CLI path is one list argument")
		check(spec.cwd == nested and spec.strategy.runtimeExecutable == "node", "Portable test execution")
		check(spec.strategy.args[1] == spec.command[2] and spec.strategy.autoAttachChildProcesses, "Debug test workers")
		check(
			vim.tbl_contains(spec.command, runner == "jest" and "--runInBand" or "--maxWorkers=1"),
			"Limit debug workers"
		)
		package.loaded["neotest-" .. runner] = nil
	end

	local dap = { adapters = {}, configurations = {}, ABORT = {} }
	package.loaded.dap = dap
	package.loaded["dap.utils"] = { pick_process = function() end }
	package.loaded["mason.settings"] = { current = { install_root_dir = root .. "/mason" } }
	vim.fn.exepath = function(name)
		check(name == "node", "Use Node, not a .cmd shim")
		return "/node path/node"
	end
	vim.uv.fs_stat = function(path)
		if path:match("dapDebugServer.js$") then
			return { type = "file" }
		end
		return saved_stat(path)
	end
	require("config.javascript-debug").setup()
	for _, ft in ipairs(ts.filetypes) do
		check(#dap.configurations[ft] >= 5, "Configure JS/JSX/TS/TSX debugging")
	end
	check(dap.configurations.typescript ~= dap.configurations.typescriptreact, "Do not share mutable config lists")
	for _, kind in ipairs({ "node", "chrome", "pwa-node", "pwa-chrome" }) do
		local config = { type = kind }
		dap.adapters[kind](function(adapter)
			check(
				adapter.host == "127.0.0.1" and adapter.port == "${port}",
				"Keep debug server local and dynamically allocated"
			)
			check(
				adapter.executable.args[1] == root .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
				"Derive Mason paths"
			)
			check(adapter.executable.args[3] == "127.0.0.1", "Bind to loopback")
		end, config)
		check(config.type:match("^pwa%-"), "Support VS Code adapter aliases")
	end
end, debug.traceback)
vim.uv.fs_stat, vim.fn.exepath = saved_stat, saved_exepath
package.loaded.dap, package.loaded["dap.utils"], package.loaded["mason.settings"] = saved_dap, saved_utils, saved_mason
vim.cmd("bwipeout!")
vim.fn.delete(root, "rf")
assert(ok, err)
print("TypeScript tests passed (project tools, hoisting, paths with spaces, Biome, test debugging, DAP aliases)")
