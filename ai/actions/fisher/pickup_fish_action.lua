--I do not give consent to copy this
local Entity = _radiant.om.Entity
local rng = _radiant.math.get_default_rng()
local PickUpFish = class()

PickUpFish.name = 'create and grab the fish'
PickUpFish.does = 'archipelago_biome:pickup_fish'
PickUpFish.args = {
dock = Entity,
fish_alias = 'string'
}
PickUpFish.think_output = {
fish = Entity
}
PickUpFish.version = 2
PickUpFish.priority = 1

function PickUpFish:start_thinking(ai, entity, args)
	self.fish = radiant.entities.create_entity(args.fish_alias, {owner = entity})
	if self.fish:get_component('stonehearth:stacks') then
		self.fish:get_component('stonehearth:stacks'):set_stacks(rng:get_int(1,10))
	end
	local entity_forms = self.fish:get_component('stonehearth:entity_forms')
	if entity_forms then
		local iconic_entity = entity_forms:get_iconic_entity()
		if iconic_entity then
			self.fish = iconic_entity
		end
	end
	if ai.CURRENT and not ai.CURRENT.carrying then
		local job_component = entity:get_component('stonehearth:job')
		local fish_table = job_component:get_curr_job_controller():remember_current_fish(self.fish)

		ai.CURRENT.carrying = self.fish
		ai:set_think_output({fish = self.fish})
	end
end

function PickUpFish:run(ai, entity, args)
	local location = radiant.entities.get_world_grid_location(args.dock)
	radiant.terrain.place_entity_at_exact_location(self.fish, location)
	radiant.check.is_entity(self.fish)

	if stonehearth.ai:prepare_to_pickup_item(ai, entity, self.fish) then
		return
	end
	assert(not radiant.entities.get_carrying(entity))

	entity:add_component('stonehearth:thought_bubble')
	:add_bubble(stonehearth.constants.thought_bubble.effects.THOUGHT,
		stonehearth.constants.thought_bubble.priorities.HUNGER+1,
		nil, args.fish_alias, '10m')

	stonehearth.ai:pickup_item(ai, entity, self.fish)
	ai:execute('stonehearth:run_pickup_effect', { location = location })
	radiant.events.trigger_async(entity, 'archipelago_biome:got_a_fish', {the_fish = self.fish})
end

return PickUpFish