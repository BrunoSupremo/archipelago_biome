-- local log = radiant.log.create_logger('ArchipelagoCave')
local ArchipelagoCave = class()
local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3
local Region3 = _radiant.csg.Region3
local rng = _radiant.math.get_default_rng()
local game_master_lib = require 'stonehearth.lib.game_master.game_master_lib'

function ArchipelagoCave:post_activate()
	self._world_generated_listener = radiant.events.listen_once(stonehearth.game_creation, 'stonehearth:world_generation_complete', self, self._on_world_generation_complete)
end

function ArchipelagoCave:_on_world_generation_complete()
	local location = radiant.entities.get_world_grid_location(self._entity)
	if location then
		location = self:move_to_edge(location)

		local cave_cube = Cube3(
			location + Point3(-3,-10,-3),
			location + Point3( 5, -5, 5)
			)
		self:remove_cube(location, cave_cube)

		self:populate_cave(location+ Point3(0,-10,0))

		self:create_tunels(location)
		self:create_entrance_space(location)

		self:add_skull(location)
	end
	radiant.entities.destroy_entity(self._entity)
end

function ArchipelagoCave:move_to_edge(location)
	local step = 0
	local at_edge, side
	repeat
		step = step +1
		at_edge, side = self:edge_neighbor(location, step)
	--code aligner comment because sublime can't understand repeat until identation ¬¬
	until at_edge
	--code aligner comment because sublime can't understand repeat until identation ¬¬

	if step == 1 then
		-- already at the edge
		return location
	end
	step = step -1 --so we move just before reaching the edge (hole)
	if side == "north" then
		location = location + Point3(0, 0, -16*step)
	end
	if side == "east" then
		location = location + Point3(16*step, 0, 0)
	end
	if side == "south" then
		location = location + Point3(0, 0, 16*step)
	end
	if side == "west" then
		location = location + Point3(-16*step, 0, 0)
	end
	return location
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

function ArchipelagoCave:add_grass(location, cave_cube)
	local max_grass_layer = 75
	if location.y <max_grass_layer+10 then
		local grass_block = radiant.terrain.get_block_types()["grass_hills_edge_1"]
		local grass_cube = cave_cube
		grass_cube.max.y = grass_cube.min.y
		grass_cube.min.y = grass_cube.min.y -1
		local grass_region = radiant.terrain.intersect_cube(grass_cube)
		for cube in grass_region:each_cube() do
			radiant.terrain.add_cube(Cube3(cube.min,cube.max,grass_block))
		end
	end
end

function ArchipelagoCave:create_tunels(location)
	local north, east, south, west
	if not radiant.terrain.is_terrain(location + Point3( 0, -1,-16)) then
		north = true
	end
	if not radiant.terrain.is_terrain(location + Point3( 16, -1, 0)) then
		east = true
	end
	if not radiant.terrain.is_terrain(location + Point3( 0, -1, 16)) then
		south = true
	end
	if not radiant.terrain.is_terrain(location + Point3(-16, -1, 0)) then
		west = true
	end
	if north then
		local tunel_cube = Cube3(
			location + Point3(-1,-10,-7),
			location + Point3( 2, -5, 0)
			)
		self:remove_cube(location,tunel_cube)
	end
	if south then
		local tunel_cube = Cube3(
			location + Point3(-1,-10, 0),
			location + Point3( 2, -5, 9)
			)
		self:remove_cube(location,tunel_cube)
	end
	if west then
		local tunel_cube = Cube3(
			location + Point3(-7,-10,-1),
			location + Point3( 0, -5, 2)
			)
		self:remove_cube(location,tunel_cube)
	end
	if east then
		local tunel_cube = Cube3(
			location + Point3( 0,-10,-1),
			location + Point3( 9, -5, 2)
			)
		self:remove_cube(location,tunel_cube)
	end
end

function ArchipelagoCave:remove_cube(location, tunel_cube)
	local cave_region = radiant.terrain.intersect_cube(tunel_cube)
	for cube in cave_region:each_cube() do
		radiant.terrain.subtract_cube(cube)
	end
	self:add_grass(location, tunel_cube)
end

function ArchipelagoCave:create_entrance_space(location)
	local north, east, south, west
	if not radiant.terrain.is_terrain(location + Point3( 0, -1,-16)) then
		north = true
	end
	if not radiant.terrain.is_terrain(location + Point3( 16, -1, 0)) then
		east = true
	end
	if not radiant.terrain.is_terrain(location + Point3( 0, -1, 16)) then
		south = true
	end
	if not radiant.terrain.is_terrain(location + Point3(-16, -1, 0)) then
		west = true
	end
	if north then
		local tunel_cube = Cube3(
			location + Point3(-3,-10,-13),
			location + Point3( 4, 0,-7)
			)
		self:remove_cube(location,tunel_cube)
		self:remove_blocking_entities(tunel_cube)
	end
	if south then
		local tunel_cube = Cube3(
			location + Point3(-3,-10, 9),
			location + Point3( 4, 0, 15)
			)
		self:remove_cube(location,tunel_cube)
		self:remove_blocking_entities(tunel_cube)
	end
	if west then
		local tunel_cube = Cube3(
			location + Point3(-13,-10,-3),
			location + Point3(-7, 0, 4)
			)
		self:remove_cube(location,tunel_cube)
		self:remove_blocking_entities(tunel_cube)
	end
	if east then
		local tunel_cube = Cube3(
			location + Point3( 9,-10,-3),
			location + Point3(15, 0, 4)
			)
		self:remove_cube(location,tunel_cube)
		self:remove_blocking_entities(tunel_cube)
	end
end

function ArchipelagoCave:remove_blocking_entities(cube)
	cube = cube:inflated(Point3(5, 2, 5))
	local intersected_entities = radiant.terrain.get_entities_in_cube(cube)
	for id, entity in pairs(intersected_entities) do
		if entity:get_component('region_collision_shape') then
			radiant.entities.destroy_entity(entity)
		end
	end
end

function ArchipelagoCave:add_skull(location)
	local north, east, south, west
	if not radiant.terrain.is_terrain(location + Point3( 0, -1,-16)) then
		north = true
	end
	if not radiant.terrain.is_terrain(location + Point3( 16, -1, 0)) then
		east = true
	end
	if not radiant.terrain.is_terrain(location + Point3( 0, -1, 16)) then
		south = true
	end
	if not radiant.terrain.is_terrain(location + Point3(-16, -1, 0)) then
		west = true
	end
	if north then
		local shifted_location = location + Point3(0,-8,-8)
		self:add_skull_x_axis(shifted_location)
	end
	if south then
		local shifted_location = location + Point3(0,-8,9)
		self:add_skull_x_axis(shifted_location)
	end
	if west then
		local shifted_location = location + Point3(-8,-8,0)
		self:add_skull_z_axis(shifted_location)
	end
	if east then
		local shifted_location = location + Point3(9,-8,0)
		self:add_skull_z_axis(shifted_location)
	end
end

function ArchipelagoCave:add_skull_x_axis(location)
	local stone_block = self:stone_block(location.y)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(0,0,0),
			location + Point3(1,8,1),
			stone_block)
		)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(-2,0,0),
			location + Point3(-1,3,1),
			stone_block)
		)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(2,0,0),
			location + Point3(3,3,1),
			stone_block)
		)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(-2,1,0),
			location + Point3(3,3,1),
			stone_block)
		)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(-3,2,0),
			location + Point3(-2,7,1),
			stone_block)
		)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(3,2,0),
			location + Point3(4,7,1),
			stone_block)
		)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(-2,6,0),
			location + Point3(3,8,1),
			stone_block)
		)

	local eye_style = rng:get_int(1,4)
	if eye_style == 1 then
		radiant.terrain.add_cube(
			Cube3(
				location + Point3(-2,5,0),
				location + Point3(3,6,1),
				stone_block)
			)
	end
	if eye_style == 2 then
		radiant.terrain.add_cube(
			Cube3(
				location + Point3(1,5,0),
				location + Point3(3,6,1),
				stone_block)
			)
	end
	if eye_style == 3 then
		radiant.terrain.add_cube(
			Cube3(
				location + Point3(-1,5,0),
				location + Point3(2,6,1),
				stone_block)
			)
	end
end

function ArchipelagoCave:add_skull_z_axis(location)
	local stone_block = self:stone_block(location.y)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(0,0,0),
			location + Point3(1,8,1),
			stone_block)
		)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(0,0,-2),
			location + Point3(1,3,-1),
			stone_block)
		)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(0,0,2),
			location + Point3(1,3,3),
			stone_block)
		)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(0,1,-2),
			location + Point3(1,3,3),
			stone_block)
		)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(0,2,-3),
			location + Point3(1,7,-2),
			stone_block)
		)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(0,2,3),
			location + Point3(1,7,4),
			stone_block)
		)
	radiant.terrain.add_cube(
		Cube3(
			location + Point3(0,6,-2),
			location + Point3(1,8,3),
			stone_block)
		)

	local eye_style = rng:get_int(1,4)
	if eye_style == 1 then
		radiant.terrain.add_cube(
			Cube3(
				location + Point3(0,5,-2),
				location + Point3(1,6,3),
				stone_block)
			)
	end
	if eye_style == 2 then
		radiant.terrain.add_cube(
			Cube3(
				location + Point3(0,5,1),
				location + Point3(1,6,3),
				stone_block)
			)
	end
	if eye_style == 3 then
		radiant.terrain.add_cube(
			Cube3(
				location + Point3(0,5,-1),
				location + Point3(1,6,2),
				stone_block)
			)
	end
end

function ArchipelagoCave:stone_block(y)
	--gets the stone type from two floors above
	local mountain_step = (y -27) /10
	return radiant.terrain.get_block_types()["rock_layer_"..mountain_step]
end

function ArchipelagoCave:populate_cave(location)
	if stonehearth.game_creation:get_game_mode() == "stonehearth:game_mode:peaceful" then
		return
	end
	local chest = radiant.entities.create_entity('archipelago_biome:monsters:cave_chest', {owner = "undead"})
	radiant.terrain.place_entity_at_exact_location(chest, location)

	local undead_population = stonehearth.population:get_population('undead')
	local skeleton_info = {
		--comment align
		tuning = 'archipelago_biome:monster_tuning:undead:cave_skeleton',
		combat_leash_range = 16,
		from_population = {
			--comment align
			role = 'skeleton',
			min = 2,
			max = 6,
			location = {},
			range = 3
		}
	}
	game_master_lib.create_citizens(undead_population, skeleton_info, location)
end

return ArchipelagoCave