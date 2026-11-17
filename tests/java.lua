-- Run from the repository root: nvim --headless -u NONE -l tests/java.lua
package.path = "./lua/?.lua;" .. package.path
local java = require("config.java")
local root = vim.fn.tempname()
local function jdk(name, version)
	local path = root .. "/" .. name
	vim.fn.mkdir(path, "p")
	vim.fn.writefile({ 'JAVA_VERSION="' .. version .. '"' }, path .. "/release")
	return path
end
local j17 = jdk("jdk17", "17.0.17")
local j21 = jdk("jdk21", "21.0.8")
local preferred = jdk("preferred21", "21.0.9")
local j8 = jdk("jdk8", "1.8.0_472")
local saved = {}
for _, name in ipairs({ "has", "environ", "glob", "executable" }) do
	saved[name] = vim.fn[name]
end
local old_system = vim.system
local old_env = {}
for _, name in ipairs({ "JAVA_HOME", "SDKMAN_DIR", "ProgramFiles", "LOCALAPPDATA" }) do
	old_env[name] = vim.env[name] or false
	vim.env[name] = nil
end
local os_name, environment, matches, brew = "linux", {}, {}, false
vim.fn.has = function(feature)
	return ((feature == "macunix" and os_name == "mac") or (feature == "win32" and os_name == "windows")) and 1 or 0
end
vim.fn.environ = function()
	return environment
end
vim.fn.glob = function(pattern)
	return matches[pattern] or {}
end
vim.fn.executable = function(cmd)
	return cmd == "brew" and brew and 1 or 0
end
vim.system = function(cmd)
	assert(vim.deep_equal(cmd, { "brew", "--prefix" }))
	return {
		wait = function()
			return { code = 0, stdout = "/test/brew\n" }
		end,
	}
end

local ok, err = xpcall(function()
	assert(#java.runtimes() == 0, "No installed JDK should produce an empty list")

	environment = { JAVA_HOME_21 = preferred }
	vim.env.JAVA_HOME = j21
	matches["/usr/lib/jvm/*"] = { j17, j21, root .. "/missing", j8 }
	local runtimes = java.runtimes()
	assert(#runtimes == 3, "Linux: discover only valid JDKs and deduplicate by major")
	local by_name = {}
	for _, runtime in ipairs(runtimes) do
		by_name[runtime.name] = runtime.path
	end
	assert(by_name["JavaSE-21"] == preferred, "Explicit JAVA_HOME_21 must take precedence")
	assert(by_name["JavaSE-17"] == j17)
	assert(by_name["JavaSE-1.8"] == j8, "Java 8 must use the JDTLS runtime name")

	environment = {}
	vim.env.JAVA_HOME = nil
	vim.env.SDKMAN_DIR = "/custom/sdkman"
	matches = { ["/custom/sdkman/candidates/java/*"] = { j17, j21 } }
	assert(#java.runtimes() == 2, "SDKMAN discovery must not hard-code patch versions")

	os_name, brew = "mac", true
	matches = {
		["/Library/Java/JavaVirtualMachines/*/Contents/Home"] = { j17 },
		["/test/brew/opt/openjdk*/libexec/openjdk.jdk/Contents/Home"] = { j21 },
	}
	assert(#java.runtimes() == 2, "macOS: discover system and keg-only Homebrew JDKs")

	os_name, brew = "windows", false
	vim.env.ProgramFiles = "C:/Program Files"
	matches = { ["C:/Program Files/Eclipse Adoptium/*"] = { j17, j21 } }
	assert(#java.runtimes() == 2, "Windows: discover JDKs under Program Files")
end, debug.traceback)

for name, fn in pairs(saved) do
	vim.fn[name] = fn
end
vim.system = old_system
for name, value in pairs(old_env) do
	vim.env[name] = value or nil
end
vim.fn.delete(root, "rf")
assert(ok, err)
print("Java discovery tests passed (Linux, macOS, Windows, SDKMAN, environment precedence)")
