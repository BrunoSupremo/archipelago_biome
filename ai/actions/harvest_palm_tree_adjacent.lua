local Entity = _radiant.om.Entity
local Point3 = _radiant.csg.Point3

local Harvest_Palm_Tree_Adjacent = radiant.class()
Harvest_Palm_Tree_Adjacent.name = 'harvest palm tree adjacent'
Harvest_Palm_Tree_Adjacent.does = 'stonehearth:harvest_renewable_resource_adjacent'
Harvest_Palm_Tree_Adjacent.args = {
resource = Entity,
owner_player_id = {
type = 'string',
default = stonehearth.ai.NIL
}
}
Harvest_Palm_Tree_Adjacent.priority = 1

function Harvest_Palm_Tree_Adjacent:start_thinking(ai, entity, args)
	if args.resource:get_uri() == "archipelago_biome:trees:palm:small" then
		ai:set_think_output({
			resource = args.resource,
			location = radiant.entities.get_world_location(args.resource) + (Point3.unit_y*5)
			})
	else
		ai:reject('not a palm tree!') 
	end
end

local ai = stonehearth.ai
return ai:create_compound_action(Harvest_Palm_Tree_Adjacent)
:execute('stonehearth:goto_entity', {
	entity = ai.PREV.resource,
	stop_distance = 0
	})
:execute('stonehearth:goto_location', {
	location = ai.BACK(2).location,
	})
:execute('stonehearth:goto_entity', {
	entity = ai.BACK(3).resource,
	stop_distance = 0
	})
-- :execute('archipelago_biome:harvest_coconut', {
-- 	resource = ai.BACK(6).item,
-- 	owner_player_id = ai.BACK(9).owner_player_id
-- 	})