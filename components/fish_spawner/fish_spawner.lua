local ArchipelagoFishSpawner = class()
local Cube3 = _radiant.csg.Cube3
local Point3 = _radiant.csg.Point3
local rng = _radiant.math.get_default_rng()
-- local log = radiant.log.create_logger('meu_log')

function ArchipelagoFishSpawner:initialize()
end

function ArchipelagoFishSpawner:activate()
	if not self._in_the_water_listener then
		self._in_the_water_listener = radiant.events.listen(self._entity, 'archipelago_biome:in_the_water', self, self.spawner_added_to_water)
	end
	if not self._on_removed_from_world_listener then
		self._on_removed_from_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_removed_from_world', self, self.spawner_removed)
	end
	if not self._on_added_to_world_listener then
		self._on_added_to_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_added_to_world', self, self.spawner_placed)
	end
end

function ArchipelagoFishSpawner:spawner_added_to_water()
	if not self.spawn_timer then
		--first time, free fish to understand how the spawn will work, without waiting
		self:try_to_spawn_fish()
		--later fish only within the timer
		self.spawn_timer = stonehearth.calendar:set_persistent_interval("ArchipelagoFishSpawner spawn_timer", "8m", radiant.bind(self, 'try_to_spawn_fish'), "8m")
	end
end

function ArchipelagoFishSpawner:spawner_removed()
	self:destroy_spawn_timer()
	self:destroy_effect()
end

function ArchipelagoFishSpawner:spawner_placed()
	local delayed_function = function ()
		--for some reason, location is nil when the on_added event fires,
		--so I have to wait 1gametick for it to be set, and it is done running inside this
		local location = radiant.entities.get_world_grid_location(self._entity)
		local intersected_entities = radiant.terrain.get_entities_at_point(location)
		local show_overlay = true
		for id, entity in pairs(intersected_entities) do
			local water_component = entity:get_component('stonehearth:water')
			if water_component then
				radiant.events.trigger_async(self._entity, 'archipelago_biome:in_the_water')
				show_overlay = false
				break
			end
		end
		if show_overlay then
			self.effect_overlay = radiant.effects.run_effect(self._entity, "archipelago_biome:effects:no_water_overlay")
		end
		self.stupid_delay:destroy()
		self.stupid_delay = nil
	end
	self.stupid_delay = stonehearth.calendar:set_persistent_timer("ArchipelagoFishSpawner delay", 0, delayed_function)
end

function ArchipelagoFishSpawner:try_to_spawn_fish()
	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		return
	end
	local cube = Cube3(location):inflated(Point3(4,7,4))
	local intersected_entities = radiant.terrain.get_entities_in_cube(cube)
	local fish_counter = 0
	for id, entity in pairs(intersected_entities) do
		if entity:get_uri() == "archipelago_biome:critters:fish" then
			fish_counter = fish_counter+1
		end
	end

	if fish_counter<2 then
		self:spawn_fish()
	else
		local spawn_chance = 1/ ( (fish_counter*fish_counter) /2)
		if rng:get_real(0,1) <= spawn_chance then
			--more fish around = fewer chances to have another spawn, but still possible
			-- 2fish = 50%, 3fish = 22%, 4fish = 12%, 5fish = 8%, etc...
			self:spawn_fish()
		end
	end
end

function ArchipelagoFishSpawner:spawn_fish()
	local location = radiant.entities.get_world_grid_location(self._entity)
	local fish = radiant.entities.create_entity('archipelago_biome:critters:fish')
	radiant.terrain.place_entity_at_exact_location(fish, location)
	fish:add_component('stonehearth:leash')
	:create_leash(location, 4, 4)
end

function ArchipelagoFishSpawner:destroy_effect()
	if self.effect_overlay then
		self.effect_overlay:stop()
		self.effect_overlay = nil
	end
end

function ArchipelagoFishSpawner:destroy_spawn_timer()
	if self.spawn_timer then
		self.spawn_timer:destroy()
		self.spawn_timer = nil
	end
end

function ArchipelagoFishSpawner:destroy()
	if self._in_the_water_listener then
		self._in_the_water_listener:destroy()
		self._in_the_water_listener = nil
	end
	if self._on_added_to_world_listener then
		self._on_added_to_world_listener:destroy()
		self._on_added_to_world_listener = nil
	end
	if self._on_removed_from_world_listener then
		self._on_removed_from_world_listener:destroy()
		self._on_removed_from_world_listener = nil
	end
	self:destroy_effect()
	self:destroy_spawn_timer()
end

return ArchipelagoFishSpawner