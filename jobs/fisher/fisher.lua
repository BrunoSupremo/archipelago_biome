local CraftingJob = require 'stonehearth.jobs.crafting_job'

local FisherClass = class()
radiant.mixin(FisherClass, CraftingJob)

-- Private Functions
function FisherClass:_create_listeners()
	CraftingJob._create_listeners(self)
	self._xp_listeners = {}

	table.insert(self._xp_listeners, radiant.events.listen(self._sv._entity, 'stonehearth:gather_renewable_resource', self, self._on_renewable_resource_gathered))
	table.insert(self._xp_listeners, radiant.events.listen(self._sv._entity, 'stonehearth:gather_resource', self, self._on_resource_gathered))
end

function FisherClass:_remove_listeners()
	CraftingJob._remove_listeners(self)
	if self._xp_listeners then
		for i, listener in ipairs(self._xp_listeners) do
			listener:destroy()
		end
		self._xp_listeners = nil
	end
end

function FisherClass:_on_renewable_resource_gathered(args)
	if args.harvested_target then
		self._job_component:add_exp(10)
	end
end

function FisherClass:_on_resource_gathered(args)
	if args.harvested_target then
		self._job_component:add_exp(10)
	end
end

return FisherClass
