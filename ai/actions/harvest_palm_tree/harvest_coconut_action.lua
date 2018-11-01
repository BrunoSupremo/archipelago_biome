local Entity = _radiant.om.Entity
local Point3 = _radiant.csg.Point3

local Harvest_Coconut = radiant.class()
Harvest_Coconut.name = 'harvest coconut'
Harvest_Coconut.does = 'archipelago_biome:harvest_coconut'
Harvest_Coconut.args = {
	resource = Entity,--tree
	owner_player_id = {
		type = 'string',--player_1
		default = stonehearth.ai.NIL,
	}
}
Harvest_Coconut.priority = 1

function Harvest_Coconut:start(ai, entity, args)
   local renewable_resource_component = args.resource:get_component('stonehearth:renewable_resource_node')
   local status_text_key = 'stonehearth:ai.actions.status_text.harvest_resource'
   if renewable_resource_component and renewable_resource_component:get_harvest_status_text() then
      status_text_key = renewable_resource_component:get_harvest_status_text()
   end
   ai:set_status_text_key(status_text_key, { target = args.resource })
end

function Harvest_Coconut:run(ai, entity, args)
	local resource = args.resource
	local id = resource:get_id()

	local factory = resource:get_component('stonehearth:renewable_resource_node')
	if not factory:is_harvestable() then
		ai:abort('resource is not currently harvestable')
	end

	if factory then
		local effect = factory:get_harvester_effect()
		ai:execute('stonehearth:run_effect', { effect = effect })

		local location = radiant.entities.get_world_grid_location(entity)
		local spawned_item = factory:spawn_resource(entity, location, args.owner_player_id)

		if spawned_item then
			local spawned_item_name = radiant.entities.get_display_name(spawned_item)
			local substitution_values = {}
			substitution_values['gather_target'] = spawned_item_name
			radiant.events.trigger_async(stonehearth.personality, 'stonehearth:journal_event',
				{entity = entity, description = 'gathering_supplies', substitutions = substitution_values})

			radiant.events.trigger_async(entity, 'stonehearth:gather_renewable_resource',
				{harvested_target = resource, spawned_item = spawned_item})
			local rng = _radiant.math.get_default_rng()
			local angle = radiant.entities.get_facing(args.resource)+180
			local random_vector = radiant.math.rotate_about_y_axis(Point3.unit_x*1.5, angle+rng:get_real(-90, 90))
			radiant.entities.move_to(entity, location+random_vector)
			stonehearth.physics:_set_free_motion(entity)

			location = radiant.entities.get_world_grid_location(spawned_item)
			random_vector = radiant.math.rotate_about_y_axis(Point3.unit_x*1.5, angle+rng:get_real(-90, 90))
			radiant.entities.move_to(spawned_item, location+random_vector-Point3(0,6,0))
			stonehearth.physics:_set_free_motion(spawned_item)
		end
	end
end

return Harvest_Coconut