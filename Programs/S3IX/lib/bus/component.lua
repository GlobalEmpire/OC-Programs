k_require 'lib/vendor/middleclass/middleclass'
k_require 'kernel/lib/role/service'
k_require 'kernel/lib/role/bus'

local OCComponentBus = class('OCComponentBus')
OCComponentBus:include(Service)
OCComponentBus:include(Bus)

function ComponentBus:on_detecthw()
	if component ~= nil then return true end -- Possibly unsafe!
end

function ComponentBus:initialize()
	self.register_service {
		name        = 'oc_component'
		desc        = 'Provides access to OC components',
		cb_detecthw = self.on_detecthw,
	}

	-- TODO
end

return ComponentBus:precheck()
