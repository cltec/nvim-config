local M = {}

function M.setup()
	local dap = require("dap")
	local ts = require("config.typescript")
	local function root()
		return ts.root(vim.api.nvim_buf_get_name(0)) or vim.fn.getcwd()
	end
	local function adapter(callback, config)
		local node = vim.fn.exepath("node")
		local script = require("mason.settings").current.install_root_dir
			.. "/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
		assert(node ~= "", "Install Node.js and put it on PATH first")
		assert(vim.uv.fs_stat(script), "Install js-debug-adapter with :Mason first")
		-- VS Code configs often use node/chrome instead of pwa-node/pwa-chrome.
		if config.type == "node" or config.type == "chrome" then
			config.type = "pwa-" .. config.type
		end
		callback({
			type = "server",
			host = "127.0.0.1",
			port = "${port}",
			executable = {
				command = node,
				args = { script, "${port}", "127.0.0.1" },
			},
		})
	end
	for _, name in ipairs({ "pwa-node", "pwa-chrome", "node", "chrome" }) do
		dap.adapters[name] = adapter
	end
	local configurations = {
		{
			name = "Node: attach to process",
			type = "pwa-node",
			request = "attach",
			processId = require("dap.utils").pick_process,
			cwd = root,
			sourceMaps = true,
			skipFiles = { "<node_internals>/**", "**/node_modules/**" },
		},
		{
			name = "Node: attach to inspector (127.0.0.1:9229)",
			type = "pwa-node",
			request = "attach",
			address = "127.0.0.1",
			port = 9229,
			cwd = root,
			sourceMaps = true,
			skipFiles = { "<node_internals>/**", "**/node_modules/**" },
		},
		{
			name = "TypeScript: launch current file with tsx",
			type = "pwa-node",
			request = "launch",
			program = "${file}",
			cwd = root,
			runtimeExecutable = "node",
			runtimeArgs = { "--import", "tsx" },
			sourceMaps = true,
			autoAttachChildProcesses = true,
			console = "integratedTerminal",
			skipFiles = { "<node_internals>/**", "**/node_modules/**" },
		},
		{
			name = "Node: launch compiled JavaScript entry",
			type = "pwa-node",
			request = "launch",
			program = function()
				local path = vim.fn.input("Compiled JS entry: ", root() .. "/", "file")
				return path ~= "" and path or dap.ABORT
			end,
			cwd = root,
			sourceMaps = true,
			console = "integratedTerminal",
			skipFiles = { "<node_internals>/**", "**/node_modules/**" },
		},
		{
			name = "Chrome: launch frontend URL",
			type = "pwa-chrome",
			request = "launch",
			url = function()
				local url = vim.fn.input("Dev server URL: ", "http://localhost:3000")
				return url ~= "" and url or dap.ABORT
			end,
			webRoot = root,
			sourceMaps = true,
		},
	}
	for _, ft in ipairs(ts.filetypes) do
		dap.configurations[ft] = vim.deepcopy(configurations)
	end
	for _, ft in ipairs({ "javascript", "javascriptreact" }) do
		table.insert(dap.configurations[ft], {
			name = "Node: launch current JavaScript file",
			type = "pwa-node",
			request = "launch",
			program = "${file}",
			cwd = root,
			sourceMaps = true,
			console = "integratedTerminal",
		})
	end
end

return M
