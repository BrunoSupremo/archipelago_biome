local ArchipelagoFishSpawner = class()
local Cube3 = _radiant.csg.Cube3
local Point3 = _radiant.csg.Point3
local rng = _radiant.math.get_default_rng()
local FISH = "archipelago_biome:critters:fish"
-- local log = radiant.log.create_logger('fish_spawner')

function ArchipelagoFishSpawner:initialize()
	self._sv.spawn_timer = nil
end

function ArchipelagoFishSpawner:activate()
	local json = radiant.entities.get_json(self)
	self.interval = json.interval or "8h"
	self.radius = json.radius or 4

	if not self._in_the_water_listener then
		self._in_the_water_listener = radiant.events.listen(self._entity, 'archipelago_biome:in_the_water', self, self.activate_the_spawner)
	end
	if not self._on_removed_from_world_listener then
		self._on_removed_from_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_removed_from_world', self, self.destroy_spawn_timer)
	end
end

function ArchipelagoFishSpawner:activate_the_spawner()
	local delayed_function = function ()
		--delayed to get location to work
		local location = radiant.entities.get_world_grid_location(self._entity)
		if location then
			--fish spawns and verifications will offset away from land
			self.location = self:push_away_from_land(location, self.radius)
		end

		if not self._sv.spawn_timer then
			--first time, free fish to understand how the spawn will work, without waiting
			self:try_to_spawn_fish()
			--later fish appear only within the timer
			self._sv.spawn_timer = stonehearth.calendar:set_persistent_interval("ArchipelagoFishSpawner spawn_timer", self.interval, radiant.bind(self, 'try_to_spawn_fish'), self.interval)
			self.__saved_variables:mark_changed()
		end
		self.stupid_delay:destroy()
		self.stupid_delay = nil
	end
	self.stupid_delay = stonehearth.calendar:set_persistent_timer("ArchipelagoFishSpawner delay", 0, delayed_function)
end

function ArchipelagoFishSpawner:try_to_spawn_fish()
	if not self.location then
		local location = radiant.entities.get_world_grid_location(self._entity)
		if not location then
			return
		end
		--fish spawns and verifications will offset away from land
		self.location = self:push_away_from_land(location, self.radius)
	end

	local bottom_height = radiant.terrain.get_point_on_terrain(self.location).y -1 --extra 1 block
	--bottom_height to make sure we are checking a space that reaches the bottom of any water level
	local cube = Cube3(self.location):inflated(Point3(self.radius, self.location.y - bottom_height, self.radius))
	local intersected_entities = radiant.terrain.get_entities_in_cube(cube)
	local fish_counter = 0
	for id, entity in pairs(intersected_entities) do
		if entity:get_uri() == FISH then
			fish_counter = fish_counter+1
		end
	end
	if fish_counter<2 then
		self:spawn_fish(self.location)
	else
		local spawn_chance = 1/ math.pow(2,fish_counter-1)
		if rng:get_real(0,1) <= spawn_chance then
			--more fish around = fewer chances to have another spawn, but still possible
			-- 2fish = 50%, 3fish = 25%, 4fish = 12,5%, 5fish = 6,25%, etc...
			self:spawn_fish(self.location)
		end
	end
end

function ArchipelagoFishSpawner:spawn_fish(location)
	local fish = radiant.entities.create_entity(FISH)
	radiant.terrain.place_entity_at_exact_location(fish, location)
	fish:add_component('stonehearth:leash')
	:create_leash(location, self.radius, self.radius)
end

function ArchipelagoFishSpawner:push_away_from_land(old_location, radius)
	local location = old_location
	local function push_away(position, offset, move_to)
		while radiant.terrain.is_terrain(position+offset) do
			position = position+move_to
		end
		return position
	end
	--neighbor blocks
	location = push_away(location, Point3( radius,0,0), Point3(-1,0,0))
	location = push_away(location, Point3(-radius,0,0), Point3( 1,0,0))
	location = push_away(location, Point3(0,0, radius), Point3(0,0,-1))
	location = push_away(location, Point3(0,0,-radius), Point3(0,0, 1))
	--diagonal blocks
	location = push_away(location, Point3( radius,0, radius), Point3(-1,0,-1))
	location = push_away(location, Point3( radius,0,-radius), Point3(-1,0, 1))
	location = push_away(location, Point3(-radius,0, radius), Point3( 1,0,-1))
	location = push_away(location, Point3(-radius,0,-radius), Point3( 1,0, 1))

	return location
end

function ArchipelagoFishSpawner:destroy_spawn_timer()
	if self._sv.spawn_timer then
		self._sv.spawn_timer:destroy()
		self._sv.spawn_timer = nil
		self.__saved_variables:mark_changed()
	end
end

function ArchipelagoFishSpawner:destroy()
	if self._in_the_water_listener then
		self._in_the_water_listener:destroy()
		self._in_the_water_listener = nil
	end
	if self._on_removed_from_world_listener then
		self._on_removed_from_world_listener:destroy()
		self._on_removed_from_world_listener = nil
	end
	self:destroy_spawn_timer()
end

return ArchipelagoFishSpawner