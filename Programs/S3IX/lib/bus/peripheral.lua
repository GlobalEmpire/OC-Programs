k_require 'lib/vendor/middleclass/middleclass'
k_require 'kernel/lib/role/service'
k_require 'kernel/lib/role/bus'

local CCPeripheralBus = class('CCPeripheralBus')
CCPeripheralBus:include(Service)
CCPeripheralBus:include(Bus)

function ComponentBus:initialize()
	self.register_service {
		name = 'cc_peripheral'
		desc = 'Provides access to CC Peripherals',
	}

	-- TODO
end

return CCPeripheralBus
