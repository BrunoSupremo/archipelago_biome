local CraftingJob = require 'stonehearth.jobs.crafting_job'

local FisherClass = class()
radiant.mixin(FisherClass, CraftingJob)

-- Private Functions
function FisherClass:_create_listeners()
	CraftingJob._create_listeners(self)
	self._xp_listeners = {}

	table.insert(self._xp_listeners, radiant.events.listen(self._sv._entity, 'stonehearth:gather_renewable_resource', self, self._on_renewable_resource_gathered))
	table.insert(self._xp_listeners, radiant.events.listen(self._sv._entity, 'stonehearth:gather_resource', self, self._on_resource_gathered))

	self._crab_trapped_listener = radiant.events.listen(self._sv._entity, 'archipelago_biome:crab_trapped', self, self._crab_trapped)
end

function FisherClass:_crab_trapped(args)
	--future auto harvest
end

function FisherClass:_remove_listeners()
	CraftingJob._remove_listeners(self)
	if self._xp_listeners then
		for i, listener in ipairs(self._xp_listeners) do
			listener:destroy()
		end
		self._xp_listeners = nil
	end

	if self._crab_trapped_listener then
		self._crab_trapped_listener:destroy()
		self._crab_trapped_listener = nil
	end
end

function FisherClass:_on_renewable_resource_gathered(args)
	if args.harvested_target then
		self._job_component:add_exp(10)
	end

	if args.harvested_target:get_uri() == "archipelago_biome:gizmos:crab_trap" then
		self:_got_a_crab(args.harvested_target)
	end
end

function FisherClass:_got_a_crab(trap)
	local rsc = trap:get_component('stonehearth:renewable_resource_node')
	rsc:pause_resource_timer()

	local ec = trap:get_component("entity_container")
	if ec then
		for id, child in ec:each_child() do
			radiant.entities.kill_entity(child)
			radiant.effects.run_effect(trap, "stonehearth:effects:abilities:snare_trap")

			return
		end
	end
end

function FisherClass:_on_resource_gathered(args)
	if args.harvested_target then
		self._job_component:add_exp(10)
	end
end

return FisherClass
