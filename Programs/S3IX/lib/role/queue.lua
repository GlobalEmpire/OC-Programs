-- Provides queue-like behavior to a class:
Queue = { buffer = {} }

function Queue.put(self, ...)
  for _, v in ipairs({...}) do
  	table.insert(self.buffer, 1, v)
	end
end

function Queue.next(self)
	return table.remove(self.buffer)
end
