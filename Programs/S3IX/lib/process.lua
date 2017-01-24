-- Process.lua - S3IX userspace process class

k_require 'lib/vendor/middleclass/middleclass'
k_require 'kernel/lib/role/queue'

local Process = class('Process')

function process:initialize(chunk)
	self.co     = coroutine.create(chunk)
	self.waters = {}
end

--[[ All processes are queues; The scheduler queues up signals the process might
be waiting for, and the process pulls them off during runtime. --]]
Process:include(Queue)

--[[ .. To accomplish this, we overload the next() function in the queue mixin
so that the process' coroutine is run. --]]
 function process:next()
	for _, msg in ipairs(self.buffer) do
  		for _, watcher in ipairs(watchers) do
  			-- Handle watcher
  		end
  		table.remove(self.buffer)
	end
	coroutine.resume(self.co)
	return coroutine.status(self.co)
end

return Process
