local ArchipelagoWave = class()
local Point3 = _radiant.csg.Point3
local Region2 = _radiant.csg.Region2
local Point2 = _radiant.csg.Point2
local rng = _radiant.math.get_default_rng()
local bad_weather_list = {
	["titans_fury:weather:doomstorm"] = true,

	["stonehearth_ace:weather:hailstorm"] = true,
	["stonehearth_ace:weather:rain:chilly"] = true,
	["stonehearth_ace:weather:under_siege"] = true,
	["stonehearth_ace:weather:whiteout"] = true,

	["stonehearth:weather:blizzard"] = true,
	["stonehearth:weather:rain"] = true,
	["stonehearth:weather:sandstorm"] = true,
	["stonehearth:weather:sandstorm:sandstormicle"] = true,
	["stonehearth:weather:thunderstorm"] = true,
	["stonehearth:weather:titanstorm"] = true
}

function ArchipelagoWave:create()
	self._is_create = true
end

function ArchipelagoWave:post_activate()
	self.timer = stonehearth.calendar:set_timer('rotate wave to correct orientation', "1m", function()
		self:rotate()
		self.timer = nil
	end)

	self._interval = 2000 + rng:get_int(1,2000)
	self.wave_timer = stonehearth.calendar:set_interval("ArchipelagoWave wave_timer", self._interval, function() self:run_effect() end, self._interval)
end

function ArchipelagoWave:run_effect()
	if not self._sv._is_visible then
		local explored_region = Region2()
		local players = stonehearth.player:get_players()
		for player_id, info in pairs(players) do
			explored_region = explored_region + stonehearth.terrain:get_visible_region(player_id):get()
		end
		local location = radiant.entities.get_world_location(self._entity)

		explored_region = explored_region:inflated(Point2(32,32))
		if not explored_region:contains(Point2(location.x,location.z)) then
			self.wave_timer:destroy()
			self._interval = self._interval+2000
			self.wave_timer = stonehearth.calendar:set_interval("ArchipelagoWave wave_timer", self._interval, function() self:run_effect() end, self._interval)
			return
		else
			self.wave_timer:destroy()
			self._interval = 2000 + rng:get_int(1,2000)
			self.wave_timer = stonehearth.calendar:set_interval("ArchipelagoWave wave_timer", self._interval, function() self:run_effect() end, self._interval)
			self._sv._is_visible = true
		end
	end

	local is_bad_weather = false
	local current_weather = stonehearth.weather:get_current_weather()
	local current_weather_uri = current_weather:get_uri()

	if bad_weather_list[current_weather_uri] then
		is_bad_weather = true
	end

	if is_bad_weather then
		radiant.effects.run_effect(self._entity, "archipelago_biome:effects:wave_bad_effect")
	else
		if self._can_have_normal_wave then
			radiant.effects.run_effect(self._entity, "archipelago_biome:effects:wave_effect")
		else
			radiant.effects.run_effect(self._entity, "archipelago_biome:effects:water_surface_effect")
		end
	end
end

function ArchipelagoWave:rotate()
	local location = radiant.entities.get_world_location(self._entity)
	if location.y >= 40 then
		radiant.entities.destroy_entity(self._entity)
		return
	end
	-- center it in the chunk (the game was spawning at 8,8 , i want 7.5, 7.5)
	if self._is_create then
		-- but only on create, else each reload would move it again and again
		radiant.entities.move_to(self._entity, location + Point3(-0.5, 0, -0.5))
		location = radiant.entities.get_world_location(self._entity)
	end

	local intersected_entities = radiant.terrain.get_entities_at_point(location)
	local water_component = nil
	for id, entity in pairs(intersected_entities) do
		water_component = entity:get_component('stonehearth:water')
		if water_component then
			break
		end
	end
	if not water_component then
		--how you got out of water? maybe the player drained it somehow
		radiant.entities.destroy_entity(self._entity)
		return
	end

	local adjacencies = Point3(0,0,0)
	if radiant.terrain.is_terrain(location + Point3(0, 0, -16)) then
		adjacencies = adjacencies + Point3(0, 0, -16)
	end
	if radiant.terrain.is_terrain(location + Point3(16, 0, 0)) then
		adjacencies = adjacencies + Point3(16, 0, 0)
	end
	if radiant.terrain.is_terrain(location + Point3(0, 0, 16)) then
		adjacencies = adjacencies + Point3(0, 0, 16)
	end
	if radiant.terrain.is_terrain(location + Point3(-16, 0, 0)) then
		adjacencies = adjacencies + Point3(-16, 0, 0)
	end
	if adjacencies.x == 0 and adjacencies.z == 0 then
		-- this is a (0,0,0) which means one of these:
		-- no land adjacency
		-- only opposing adjacency, like right and left or up and down
		-- fully surrounded, a lake
		-- around 1% of waves end up in this situation
		self._can_have_normal_wave = false
	else
		if adjacencies.x ~= 0 and adjacencies.z ~= 0 then
			-- if both x and z got coords, than it is a diagonal
			-- around 21% of waves end up in this situation
			self._can_have_normal_wave = false
		else
			-- if only x or z got coords, than it is just pure up, down, left or right
			self._can_have_normal_wave = true
		end
	end
	self._entity:get_component('mob'):turn_to_face_point(location + adjacencies)

	-- move it up to the water surface
	radiant.entities.move_to(self._entity, Point3(location.x, water_component:get_water_level(), location.z))
end

function ArchipelagoWave:destroy()
	if self.wave_timer then
		self.wave_timer:destroy()
		self.wave_timer = nil
	end
end

return ArchipelagoWave