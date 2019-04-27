local Entity = _radiant.om.Entity

local GetCrabAdjacent = radiant.class()
GetCrabAdjacent.name = 'harvest crab trap adjacent'
GetCrabAdjacent.does = 'archipelago_biome:get_crab_adjacent'
GetCrabAdjacent.args = {
	trap = Entity
}
GetCrabAdjacent.priority = 0

function GetCrabAdjacent:start(ai, entity, args)
	local crab_spawner = args.trap:get_component('archipelago_biome:crab_spawner')
	local status_text_key = 'stonehearth:ai.actions.status_text.harvest_resource'
	ai:set_status_text_key(status_text_key, { target = args.trap })
end

function GetCrabAdjacent:run(ai, entity, args)
	local crab_trap = args.trap

	local crab_spawner = crab_trap:get_component('archipelago_biome:crab_spawner')
	if not crab_spawner:harvestable() then
		ai:abort('crab_trap is not currently harvestable')
	end

	radiant.entities.turn_to_face(entity, crab_trap)
	ai:execute('stonehearth:run_effect', { effect = "fiddle" })

	local location = radiant.entities.get_world_grid_location(entity)
	local spawned_item = crab_spawner:spawn_resource(entity, location)

	radiant.events.trigger_async(entity, 'stonehearth:gather_renewable_resource',
		{harvested_target = crab_trap, spawned_item = spawned_item})

end

return GetCrabAdjacent