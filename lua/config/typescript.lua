local M = {}
local adapters = {}
M.filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }

local function directory(path)
	local stat = vim.uv.fs_stat(path)
	return stat and stat.type == "directory" and path or vim.fs.dirname(path)
end

function M.root(path)
	return vim.fs.root(path, { "package.json" }) or directory(path)
end

-- Resolve JS entrypoints, not .bin shell/.cmd wrappers. Never download tools.
-- Walking ancestors also supports hoisted node_modules in npm/pnpm workspaces.
function M.tool(package_name, bin_name, path)
	local dir = directory(path)
	while dir do
		local package_dir = dir .. "/node_modules/" .. package_name
		local file = io.open(package_dir .. "/package.json", "r")
		if file then
			local contents = file:read("*a")
			file:close()
			local ok, package = pcall(vim.json.decode, contents)
			local bin = ok and package.bin
			local entry = type(bin) == "table" and bin[bin_name] or bin
			if type(entry) == "string" and vim.uv.fs_stat(package_dir .. "/" .. entry) then
				return vim.fs.normalize(package_dir .. "/" .. entry)
			end
		end
		local parent = vim.fs.dirname(dir)
		if parent == dir then
			break
		end
		dir = parent
	end
end

function M.formatter()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		return
	end
	local biome = vim.fs.find({ "biome.json", "biome.jsonc" }, { path = directory(path), upward = true })[1]
	local entry = M.tool(biome and "@biomejs/biome" or "prettier", biome and "biome" or "prettier", path)
	if not entry then
		return
	end
	local args = { vim.fn.shellescape(entry) }
	vim.list_extend(
		args,
		biome and { "format", "--stdin-file-path", vim.fn.shellescape(path) }
			or { "--stdin-filepath", vim.fn.shellescape(path) }
	)
	return {
		exe = "node",
		args = args,
		stdin = true,
		cwd = M.root(path),
	}
end

-- Both adapters split their command strings on whitespace. Supply only 'node'
-- there, then insert the real CLI as a list argument (safe with Windows/spaces).
function M.test_adapter(runner)
	if adapters[runner] then
		return adapters[runner]
	end
	local options = runner == "vitest" and { vitestCommand = "node" } or { jestCommand = "node" }
	options.cwd = M.root
	options[runner .. "ConfigFile"] = function(path)
		local names = {}
		for _, prefix in ipairs(runner == "jest" and { "jest" } or { "vitest", "vite" }) do
			for _, extension in ipairs({ "ts", "js", "mts", "mjs", "cts", "cjs" }) do
				table.insert(names, prefix .. ".config." .. extension)
			end
		end
		return vim.fs.find(names, { path = directory(path), upward = true })[1] or ""
	end
	local adapter = require("neotest-" .. runner)(options)
	local build_spec = adapter.build_spec
	adapter.build_spec = function(args)
		local path = args.tree:data().path
		local entry =
			assert(M.tool(runner, runner, path), "Install " .. runner .. " in this project's node_modules first")
		local spec = build_spec(args)
		if not spec then
			return
		end
		table.insert(spec.command, 2, entry)
		spec.cwd = spec.cwd or M.root(path)
		if args.strategy == "dap" then
			if runner == "jest" then
				table.insert(spec.command, "--runInBand")
			else
				vim.list_extend(spec.command, { "--no-file-parallelism", "--maxWorkers=1" })
			end
			spec.strategy.runtimeExecutable = "node"
			spec.strategy.args = vim.list_slice(spec.command, 2)
			spec.strategy.autoAttachChildProcesses = true
			spec.strategy.sourceMaps = true
			spec.strategy.skipFiles = { "<node_internals>/**", "**/node_modules/**" }
		end
		return spec
	end
	adapters[runner] = adapter
	return adapter
end

return M
