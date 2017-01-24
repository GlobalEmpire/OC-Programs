function spawn_service_manager()
	local service_manager = {}
	local services        = {}
 
	local function create_service(chunk)
		local service = {}

		-- TODO 
 
		return service
	end
 
	function service_manager.kldload(chunk)
		local service = create_service(chunk)
		table.insert(services, service)
		service() -- Initialize the service
	end
 
	return service_manager
end
 
function spawn_vfs()
	local vfs         = {}
	local handles     = {}
	local mountpoints = {}
	local filesystems = {}
 
	function vfs.open()  end
	function vfs.close() end
	function vfs.read()  end
	function vfs.write() end
 
	return vfs
end
 
function spawn_scheduler(init)
	local scheduler = {}
	local processes = {}
 
	function scheduler.spawn(chunk)
		local proc = create_process(chunk)
		table.insert(processes, proc)
	end
 
	function scheduler.run()
		for index, process in ipairs(processes) do
			local status = process.next()
			if status == 'dead' then
				process = nil
				table.remove(processes, index)
				print("Process quit")
			end
		end
		-- return scheduler.run()
	end
 
	-- Bootstrap the init system:
	scheduler.spawn(init)
	return scheduler
end
 
function _main()
	local scheduler = spawn_scheduler(load(""))
	local service   = spawn_service_manager()
	local vfs       = spawn_vfs()
 
	scheduler.run()
end
 
_main()
