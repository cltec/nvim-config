local M = {}

-- Discover installed JDKs rather than committing machine-specific SDK versions.
-- JAVA_HOME_<major> takes precedence, then JAVA_HOME, then standard locations.
function M.runtimes()
	local found = {}
	local function add(path)
		if not path or path == "" then
			return
		end
		path = vim.fs.normalize(path)
		local release = path .. "/release"
		if vim.fn.filereadable(release) ~= 1 then
			return
		end
		local contents = table.concat(vim.fn.readfile(release), "\n")
		local version = contents:match('JAVA_VERSION="([^"]+)"')
		local major = version and tonumber(version:match("^1%.(%d+)") or version:match("^(%d+)"))
		if major and not found[major] then
			found[major] = { name = "JavaSE-" .. (major == 8 and "1.8" or major), path = path }
		end
	end

	for name, value in pairs(vim.fn.environ()) do
		if name:match("^JAVA_HOME_%d+$") then
			add(value)
		end
	end
	add(vim.env.JAVA_HOME)

	local home = vim.fn.expand("~")
	local patterns = {
		(vim.env.SDKMAN_DIR or home .. "/.sdkman") .. "/candidates/java/*",
		home .. "/.jdks/*",
	}
	if vim.fn.has("macunix") == 1 then
		vim.list_extend(patterns, {
			"/Library/Java/JavaVirtualMachines/*/Contents/Home",
			home .. "/Library/Java/JavaVirtualMachines/*/Contents/Home",
		})
		-- Homebrew's keg-only JDKs need not be registered with /usr/libexec/java_home.
		if vim.fn.executable("brew") == 1 then
			local result = vim.system({ "brew", "--prefix" }, { text = true }):wait()
			if result.code == 0 then
				table.insert(patterns, vim.trim(result.stdout) .. "/opt/openjdk*/libexec/openjdk.jdk/Contents/Home")
			end
		end
	elseif vim.fn.has("win32") == 1 then
		for _, name in ipairs({ "ProgramFiles", "LOCALAPPDATA" }) do
			local base = vim.env[name]
			if base then
				table.insert(patterns, base .. "/Java/*")
				table.insert(patterns, base .. "/Eclipse Adoptium/*")
			end
		end
	else
		table.insert(patterns, "/usr/lib/jvm/*")
	end
	for _, pattern in ipairs(patterns) do
		for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
			add(path)
		end
	end

	local runtimes = vim.tbl_values(found)
	table.sort(runtimes, function(a, b)
		return a.name < b.name
	end)
	return runtimes
end

return M
