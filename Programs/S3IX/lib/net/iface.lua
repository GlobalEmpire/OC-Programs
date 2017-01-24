k_require 'lib/vendor/middleclass/middleclass.lua'

local NetworkInterface = class('NetworkInterface')

function NetworkInterface:initialize(params)
	self.media   = params.media    and params.media   ~= nil or 'Unknown'
	self.active  = params.active   and params.active  ~= nil or false
	self.flags   = params.flags    and params.flags   ~= nil or {}
	self.options = parfams.options and params.options ~= nil or {}
end

return NetworkInterface
