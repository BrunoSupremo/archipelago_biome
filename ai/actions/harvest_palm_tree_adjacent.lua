local Entity = _radiant.om.Entity
local Point3 = _radiant.csg.Point3
local Region3 = _radiant.csg.Region3

local Harvest_Palm_Tree_Adjacent = radiant.class()
Harvest_Palm_Tree_Adjacent.name = 'harvest palm tree adjacent'
Harvest_Palm_Tree_Adjacent.does = 'stonehearth:harvest_renewable_resource_adjacent'
Harvest_Palm_Tree_Adjacent.args = {
resource = Entity,
owner_player_id = {
type = 'string',
default = stonehearth.ai.NIL,
}
}
Harvest_Palm_Tree_Adjacent.priority = 1

function Harvest_Palm_Tree_Adjacent:start_thinking(ai, entity, args)
	if args.resource:get_uri() == "archipelago_biome:trees:palm:small" then
		ai:set_think_output({
			location = radiant.entities.get_world_grid_location(args.resource)+Point3(0,5,0)
			})
	else
		ai:reject('not a palm tree!') 
	end
end

function Harvest_Palm_Tree_Adjacent:start(ai, entity, args)
	self._vertical_pathing_region = args.resource:add_component('vertical_pathing_region')
	local ladder_region = self._vertical_pathing_region:get_region():get()
	local region = Region3()
	local location = radiant.entities.get_world_grid_location(args.resource)
	region:add_point(location)
	region = region:inflated(Point3(7,7,7))
	self._vertical_pathing_region:set_region(region)
end

local ai = stonehearth.ai
return ai:create_compound_action(Harvest_Palm_Tree_Adjacent)
:execute('stonehearth:goto_location', {
	location = ai.PREV.location
	})
-- :execute('archipelago_biome:harvest_coconut', {
-- 	resource = ai.BACK(6).item,
-- 	owner_player_id = ai.BACK(9).owner_player_id
-- 	})