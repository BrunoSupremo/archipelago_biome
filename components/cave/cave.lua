local ArchipelagoCave = class()
local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3
local Region3 = _radiant.csg.Region3
local rng = _radiant.math.get_default_rng()
local game_master_lib = require 'stonehearth.lib.game_master.game_master_lib'

function ArchipelagoCave:post_activate()
	self._world_generated_listener = radiant.events.listen_once(stonehearth.game_creation, 'stonehearth:world_generation_complete', self, self._on_world_generation_complete)
	
	-- self.timer = stonehearth.calendar:set_timer('bypass for debug testing', "1m", function()
	-- 	self:_on_world_generation_complete()
	-- 	self.timer = nil
	-- end)
end

function ArchipelagoCave:_on_world_generation_complete()
	local location = radiant.entities.get_world_grid_location(self._entity)
	local rotation = 0
	if location then
		location, rotation = self:move_to_edge(location)
		local landmark = radiant.entities.create_entity("archipelago_biome:landmark:summon_stone:pirate_cave")
		radiant.entities.turn_to(landmark, rotation)
		radiant.terrain.place_entity_at_exact_location(landmark, location)
	end
	radiant.entities.destroy_entity(self._entity)
end

function ArchipelagoCave:move_to_edge(location)
	local step = 0
	local at_edge, side
	repeat
		step = step +1
		at_edge, side = self:edge_neighbor(location, step)
	until at_edge

	step = step -1 --so we move just before reaching the edge (hole)
	local rotation = 0
	if side == "north" then
		location = location + Point3(0, 0, -16*step)
		rotation =  0
	end
	if side == "east" then
		location = location + Point3(16*step, 0, 0)
		rotation =  270
	end
	if side == "south" then
		location = location + Point3(0, 0, 16*step)
		rotation =  180
	end
	if side == "west" then
		location = location + Point3(-16*step, 0, 0)
		rotation =  90
	end
	return location, rotation
end

function ArchipelagoCave:edge_neighbor(location, step)
	if not radiant.terrain.is_terrain(location + Point3(0, -1, -16*step)) then
		return true, "north"
	end
	if not radiant.terrain.is_terrain(location + Point3(16*step, -1, 0)) then
		return true, "east"
	end
	if not radiant.terrain.is_terrain(location + Point3(0, -1, 16*step)) then
		return true, "south"
	end
	if not radiant.terrain.is_terrain(location + Point3(-16*step, -1, 0)) then
		return true, "west"
	end
	return false, nil
end

return ArchipelagoCave