-- bootrd.lua - functions for handling the bootrd

function k_require(path)
	path = path .. '.lua'
	local chunk = load(BOOTRD[path])
	return chunk()
end
