local ArchipelagoWave = class()
local Point3 = _radiant.csg.Point3
local rng = _radiant.math.get_default_rng()

function ArchipelagoWave:post_activate()
	self.timer = stonehearth.calendar:set_timer('rotate wave to correct orientation', "1m", function()
		self:rotate()
		self.timer = nil
	end)

	local interval = 2000 + rng:get_int(1,2000)
	self.wave_timer = stonehearth.calendar:set_interval("ArchipelagoWave wave_timer", interval, function() self:run_effect() end, interval)
end

function ArchipelagoWave:run_effect()
	--todo: change effect based on weather/season
	radiant.effects.run_effect(self._entity, "archipelago_biome:effects:wave_effect")
end

function ArchipelagoWave:rotate()
	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		return
	else
		if location.y>40 then
			--to avoid waves in the foothills/mountains rivers
			radiant.entities.destroy_entity(self._entity)
			return
		end
	end
	local intersected_entities = radiant.terrain.get_entities_at_point(location)
	local has_water=false
	for id, entity in pairs(intersected_entities) do
		if entity:get_component('stonehearth:water') then
			has_water = true
			break
		end
	end
	if not has_water then
		radiant.entities.destroy_entity(self._entity)
		return
	end
	local x = 0
	local z = 0
	local terrain_count = 0
	for i=-32, 32, 16 do
		for j=-32, 32, 16 do
			if radiant.terrain.is_terrain(location + Point3(i, 0, j)) then
				terrain_count = terrain_count+1
				x = x+i
				z = z+j
			end
		end
	end
	if terrain_count <1 then
		--this means that it spawned at the map borders, so remove itself
		radiant.entities.destroy_entity(self._entity)
		return
	end
	x = x/terrain_count
	z = z/terrain_count
	if x == 0 and z == 0 then
		--this means that it has no direction to look, e.g. a tie between pointing right and left
		radiant.entities.destroy_entity(self._entity)
		return
	end
	self._entity:get_component('mob'):turn_to_face_point(location + Point3(x, location.y, z))
end

function ArchipelagoWave:destroy()
	if self.wave_timer then
		self.wave_timer:destroy()
		self.wave_timer = nil
	end
end

return ArchipelagoWave