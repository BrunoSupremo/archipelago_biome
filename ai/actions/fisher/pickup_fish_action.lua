local Entity = _radiant.om.Entity
local rng = _radiant.math.get_default_rng()
local PickUpFish = class()

PickUpFish.name = 'create and grab the fish'
PickUpFish.does = 'archipelago_biome:pickup_fish'
PickUpFish.args = {
	dock = Entity,
	current_loot_entity = Entity
}
PickUpFish.think_output = {}
PickUpFish.version = 2
PickUpFish.priority = 1

function PickUpFish:start_thinking(ai, entity, args)
	if ai.CURRENT and (not ai.CURRENT.carrying) then
		ai.CURRENT.carrying = args.current_loot_entity
		ai:set_think_output()
	end
end

function PickUpFish:run(ai, entity, args)
	local current_loot_entity = args.current_loot_entity
	local current_loot_entity_uri = args.current_loot_entity:get_uri()
	local entity_forms = current_loot_entity:get_component('stonehearth:entity_forms')
	if entity_forms then
		local iconic_entity = entity_forms:get_iconic_entity()
		if iconic_entity then
			current_loot_entity = iconic_entity
		end
	end

	radiant.check.is_entity(current_loot_entity)

	if stonehearth.ai:prepare_to_pickup_item(ai, entity, current_loot_entity) then
		return
	end
	assert(not radiant.entities.get_carrying(entity))

	entity:add_component('stonehearth:thought_bubble')
	:add_bubble(stonehearth.constants.thought_bubble.effects.THOUGHT,
		stonehearth.constants.thought_bubble.priorities.HUNGER+1,
		nil, current_loot_entity_uri, '10m')

	stonehearth.ai:pickup_item(ai, entity, current_loot_entity)
	local location = radiant.entities.get_world_grid_location(args.dock)
	ai:execute('stonehearth:run_pickup_effect', { location = location })
	radiant.events.trigger(entity, 'archipelago_biome:got_a_fish', {})
end

return PickUpFish