local Entity = _radiant.om.Entity
local rng = _radiant.math.get_default_rng()
local PickUpFish = class()

PickUpFish.name = 'create and grab the fish'
PickUpFish.does = 'archipelago_biome:pickup_fish'
PickUpFish.args = {
	dock = Entity
}
PickUpFish.think_output = {}
PickUpFish.version = 2
PickUpFish.priority = 1

function PickUpFish:start_thinking(ai, entity, args)
	if ai.CURRENT and (not ai.CURRENT.carrying) then
		local job_component = entity:get_component('stonehearth:job')
		local current_loot = job_component:get_curr_job_controller():get_current_loot()

		ai.CURRENT.carrying = current_loot.entity
		ai:set_think_output()
	end
end

function PickUpFish:run(ai, entity, args)
	local job_component = entity:get_component('stonehearth:job')
	local current_loot = job_component:get_curr_job_controller():get_current_loot()

	local location = radiant.entities.get_world_grid_location(args.dock)
	radiant.terrain.place_entity_at_exact_location(current_loot.entity, location)
	radiant.check.is_entity(current_loot.entity)

	if stonehearth.ai:prepare_to_pickup_item(ai, entity, current_loot.entity) then
		return
	end
	assert(not radiant.entities.get_carrying(entity))

	entity:add_component('stonehearth:thought_bubble')
	:add_bubble(stonehearth.constants.thought_bubble.effects.THOUGHT,
		stonehearth.constants.thought_bubble.priorities.HUNGER+1,
		nil, current_loot.alias, '10m')

	stonehearth.ai:pickup_item(ai, entity, current_loot.entity)
	ai:execute('stonehearth:run_pickup_effect', { location = location })
	radiant.events.trigger_async(entity, 'archipelago_biome:got_a_fish', {})
end

return PickUpFish