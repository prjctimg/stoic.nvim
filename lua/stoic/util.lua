local U = {}

function U.error(op, error_msg)
	local msg = string.format("Stoic: Error during %s: %s", op, error_msg or "unknown error")
	vim.notify(msg, vim.log.levels.ERROR)
end

return U
