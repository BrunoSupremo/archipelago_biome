local Entity = _radiant.om.Entity
local Harvest_Palm_Tree = class()

Harvest_Palm_Tree.name = 'harvest palm tree'
Harvest_Palm_Tree.does = 'stonehearth:harvest_renewable_resource_adjacent'
Harvest_Palm_Tree.args = {
	resource = Entity,--palm tree
	owner_player_id = {
		type = 'string',--player_1
		default = stonehearth.ai.NIL,
	}
}
Harvest_Palm_Tree.version = 2
Harvest_Palm_Tree.priority = 1

function Harvest_Palm_Tree:start_thinking(ai, entity, args)
	local climbable = radiant.entities.get_entity_data(args.resource, 'archipelago_biome:climbable')
	if climbable and climbable.path then
		ai:set_think_output({
			path = climbable.path,
			resource = args.resource,
			owner_player_id = args.owner_player_id
			})
	end
end

local ai = stonehearth.ai
return ai:create_compound_action(Harvest_Palm_Tree)
:execute('archipelago_biome:climb_up', {
	path = ai.PREV.path,
	resource = ai.PREV.resource
	})
:execute('archipelago_biome:harvest_coconut', {
	resource = ai.BACK(2).resource,
	owner_player_id = ai.BACK(2).owner_player_id
	})