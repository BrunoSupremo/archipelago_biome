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
   local direct_path_finder = _radiant.sim.create_direct_path_finder(entity)
      :set_start_location(ai.CURRENT.location)
      :set_end_location(ai.CURRENT.location+ (Point3.unit_y*5))
      :set_allow_incomplete_path(true)
      :set_reversible_path(true)

   local path = direct_path_finder:get_path()
	if args.resource:get_uri() == "archipelago_biome:trees:palm:small" then
		ai:set_think_output({
			path=path
			})
	else
		ai:reject('not a palm tree!') 
	end
end

local ai = stonehearth.ai
return ai:create_compound_action(Harvest_Palm_Tree_Adjacent)
:execute('stonehearth:follow_path', {
	path = ai.PREV.path
	})
-- :execute('archipelago_biome:harvest_coconut', {
-- 	resource = ai.BACK(6).item,
-- 	owner_player_id = ai.BACK(9).owner_player_id
-- 	})