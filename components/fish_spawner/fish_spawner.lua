local ArchipelagoFishSpawner = class()
local Cube3 = _radiant.csg.Cube3
local Point3 = _radiant.csg.Point3
local rng = _radiant.math.get_default_rng()
-- local log = radiant.log.create_logger('meu_log')

function ArchipelagoFishSpawner:initialize()
	--this class was super simple before I started adapting it to also control crab traps...
	self._sv.spawn_timer = nil
	self._sv.fish = nil
end

function ArchipelagoFishSpawner:activate()
	local json = radiant.entities.get_json(self)
	self.animal = json.spawn.animal or "archipelago_biome:critters:fish"
	self.max = json.spawn.max or 100
	self.start_inside_spawner = json.spawn.start_inside_spawner or false
	self.interval = json.interval or "8h"
	self.requires_water = json.requires_water or false
	self.effect_radius = json.effect_radius or 4

	if not self._in_the_water_listener then
		self._in_the_water_listener = radiant.events.listen(self._entity, 'archipelago_biome:in_the_water', self, self.activate_the_spawner)
	end
	if not self._on_removed_from_world_listener then
		self._on_removed_from_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_removed_from_world', self, self.spawner_removed)
	end
	if not self._on_added_to_world_listener then
		self._on_added_to_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_added_to_world', self, self.spawner_placed)
	end
	
	local rsc = self._entity:get_component('stonehearth:renewable_resource_node')
	if rsc then
		rsc:pause_resource_timer()
	end
end

function ArchipelagoFishSpawner:activate_the_spawner()
	if not self._sv.spawn_timer then
		--first time, free fish to understand how the spawn will work, without waiting
		self:try_to_spawn_fish()
		--later fish appear only within the timer
		self._sv.spawn_timer = stonehearth.calendar:set_persistent_interval("ArchipelagoFishSpawner spawn_timer", self.interval, radiant.bind(self, 'try_to_spawn_fish'), self.interval)
		self.__saved_variables:mark_changed()

		local rsc = self._entity:get_component('stonehearth:renewable_resource_node')
		if rsc then
			rsc:pause_resource_timer()
		end
	end
end

function ArchipelagoFishSpawner:spawner_removed()
	self:destroy_spawn_timer()
	self:destroy_effect()
	if self._sv.fish then
		local task = self._sv.fish:get_component('stonehearth:ai')
		:get_task_group('stonehearth:unit_control')
		:get_task_with_activity_name("stonehearth:goto_closest_standable_location")
		if task then
			task:destroy()
		end
		self._sv.fish = nil
		self.__saved_variables:mark_changed()
	end
end

function ArchipelagoFishSpawner:spawner_placed()
	local delayed_function = function ()
		--for some reason, location is nil when the on_added event fires,
		--so I have to wait 1gametick for it to be set, and it is done running inside this
		if self.requires_water then
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
		else
			self:activate_the_spawner()
		end
		self.stupid_delay:destroy()
		self.stupid_delay = nil
	end
	self.stupid_delay = stonehearth.calendar:set_persistent_timer("ArchipelagoFishSpawner delay", 0, delayed_function)
end

function ArchipelagoFishSpawner:try_to_spawn_fish()
	local ec = self._entity:get_component("entity_container")
	if ec then
		for id, child in ec:each_child() do
			--if it has a child (trapped) it should do nothing, just wait until harvested.
			return
		end
	end
	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		return
	end
	local bottom_height = radiant.terrain.get_point_on_terrain(location).y -1 --extra 1 block
	--bottom_height to make sure we are checking a space that reaches the bottom of any water level
	local cube = Cube3(location):inflated(Point3(self.effect_radius, location.y - bottom_height, self.effect_radius))
	local intersected_entities = radiant.terrain.get_entities_in_cube(cube)
	local fish_counter = 0
	local last_fish_found = nil
	for id, entity in pairs(intersected_entities) do
		if entity:get_uri() == self.animal then
			fish_counter = fish_counter+1
			last_fish_found = entity
		end
	end
	if fish_counter >= self.max then
		self:approach_task(last_fish_found,location)
		return --max amount allowed already reached, abort
	end
	if fish_counter<2 then
		self:spawn_fish(location)
	else
		local spawn_chance = 1/ math.pow(2,fish_counter-1)
		if rng:get_real(0,1) <= spawn_chance then
			--more fish around = fewer chances to have another spawn, but still possible
			-- 2fish = 50%, 3fish = 25%, 4fish = 12,5%, 5fish = 6,25%, etc...
			self:spawn_fish(location)
		end
	end
end

function ArchipelagoFishSpawner:spawn_fish(location)
	local fish = radiant.entities.create_entity(self.animal)
	if self.start_inside_spawner then
		radiant.terrain.place_entity_at_exact_location(fish, location)
	else
		local far_location = radiant.terrain.find_placement_point(location, self.effect_radius, self.effect_radius, fish)
		radiant.terrain.place_entity_at_exact_location(fish, far_location)
		self:approach_task(fish,location)
	end
	fish:add_component('stonehearth:leash')
	:create_leash(location, self.effect_radius, self.effect_radius)
end

function ArchipelagoFishSpawner:approach_task(fish,location)
	self._sv.fish = fish
	self.__saved_variables:mark_changed()

	local task = fish:get_component('stonehearth:ai')
	:get_task_group('stonehearth:unit_control')
	:get_task_with_activity_name("stonehearth:goto_closest_standable_location")
	if task then
		return --someone is already capturing it
	end

	self._approach_task = fish:get_component('stonehearth:ai')
	:get_task_group('stonehearth:unit_control')
	:create_task('stonehearth:goto_closest_standable_location', {
		location = location,
		max_radius = 5,
		})
	:set_priority(10)
	:once()
	:notify_completed(
		function ()
			self._approach_task = nil
			local mob = fish:add_component('mob')
			mob:set_mob_collision_type(_radiant.om.Mob.NONE)
			radiant.entities.add_child(self._entity, fish, Point3.zero)
			radiant.entities.add_buff(fish, 'stonehearth:buffs:snared')
			local rsc = self._entity:get_component('stonehearth:renewable_resource_node')
			if rsc then
				rsc:resume_resource_timer()
			end
			self._sv.fish = nil
			self.__saved_variables:mark_changed()
		end
		)
	:start()
end

function ArchipelagoFishSpawner:destroy_effect()
	if self.effect_overlay then
		self.effect_overlay:stop()
		self.effect_overlay = nil
	end
end

function ArchipelagoFishSpawner:destroy_spawn_timer()
	if self._sv.spawn_timer then
		self._sv.spawn_timer:destroy()
		self._sv.spawn_timer = nil
	end
	self.__saved_variables:mark_changed()
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