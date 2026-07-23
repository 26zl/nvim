local lockfile = assert(vim.env.NVIM_LOCKFILE, "NVIM_LOCKFILE is required")
local lock = vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))
local plugins = require("lazy.core.config").plugins
local errors = {}

for name in pairs(plugins) do
	if not lock[name] then
		table.insert(errors, ("plugin %s is missing from the lockfile"):format(name))
	end
end

for name, entry in pairs(lock) do
	local commit = type(entry) == "table" and entry.commit or nil
	if type(commit) ~= "string" or #commit ~= 40 or not commit:match("^%x+$") then
		table.insert(errors, ("plugin %s has an invalid locked commit"):format(name))
	else
		local directory = vim.fn.stdpath("data") .. "/lazy/" .. name
		local head = vim.trim(vim.fn.system({ "git", "-C", directory, "rev-parse", "HEAD" }))
		if vim.v.shell_error ~= 0 then
			table.insert(errors, ("plugin %s is not installed as a Git checkout"):format(name))
		elseif head ~= commit then
			table.insert(errors, ("plugin %s is not at its locked commit"):format(name))
		end
	end
end

if #errors > 0 then
	vim.api.nvim_echo({ { table.concat(errors, "\n"), "ErrorMsg" } }, true, {})
	os.exit(1)
end
