local CraftingJob = require 'stonehearth.jobs.crafting_job'

local FisherClass = class()
radiant.mixin(FisherClass, CraftingJob)

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

	if self._crab_trapped_listener then
		self._crab_trapped_listener:destroy()
		self._crab_trapped_listener = nil
	end
end

function FisherClass:_on_renewable_resource_gathered(args)
	if args.harvested_target then
		self._job_component:add_exp(1) --base exp for any renewable harvest
	end

	if args.harvested_target:get_uri() == "archipelago_biome:beach:oyster" then
		self._job_component:add_exp(10) --extra for oysters

		if args.spawned_item:get_uri() == "archipelago_biome:resources:pearl:black" then
			self._job_component:add_exp(5) --another extra for black pearls
		end
	end

	if args.harvested_target:get_uri() == "archipelago_biome:gizmos:crab_trap" then
		stonehearth.ai:reconsider_entity(args.harvested_target)
		self:_got_a_crab(args.harvested_target)
		self._job_component:add_exp(10) --extra for crabs traps
	end
end

function FisherClass:_got_a_crab(crab_trap)
	local rsc = crab_trap:get_component('stonehearth:renewable_resource_node')
	rsc:pause_resource_timer()

	local ec = crab_trap:get_component("entity_container")
	if ec then
		for id, child in ec:each_child() do
			ec:remove_child(id)
			radiant.entities.kill_entity(child)
			radiant.effects.run_effect(crab_trap, "stonehearth:effects:abilities:snare_trap")

			return
		end
	end
end

function FisherClass:_on_resource_gathered(args)
	if args.harvested_target then --fish (as an entity) was the only possibility, not used now
		self._job_component:add_exp(10)
	end
end

return FisherClass