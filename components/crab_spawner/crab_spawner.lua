local ArchipelagoCrabSpawner = class()
local Cube3 = _radiant.csg.Cube3
local Point3 = _radiant.csg.Point3
local CRAB = "archipelago_biome:critters:crab"
local COLLAR = "archipelago_biome:critters:crab:collar"
local rng = _radiant.math.get_default_rng()
-- local log = radiant.log.create_logger('crab_spawner')

function ArchipelagoCrabSpawner:initialize()
	-- log:error("initialize")
	self._sv.spawn_timer = nil
	self._sv.crab = nil
end

function ArchipelagoCrabSpawner:activate()
	-- log:error("activate")
	local json = radiant.entities.get_json(self)
	self.interval = json.interval or "8h"
	self.radius = json.radius or 15

	if not self._on_removed_from_world_listener then
		self._on_removed_from_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_removed_from_world', self, self.spawner_removed)
	end
	if not self._on_added_to_world_listener then
		self._on_added_to_world_listener = radiant.events.listen(self._entity, 'archipelago_biome:in_the_water', self, self.activate_the_spawner)
	end
	
	self:ready_to_harvest(false)
end

function ArchipelagoCrabSpawner:activate_the_spawner()
	-- log:error("activate_the_spawner")
	local delayed_function = function ()
		-- log:error("activate_the_spawner delayed")
		if not self._sv.spawn_timer then
			--try to spawn right after being placed
			self:try_to_spawn_crab()
			--later crabs appear only within the timer
			self._sv.spawn_timer = stonehearth.calendar:set_persistent_interval("ArchipelagoCrabSpawner spawn_timer", self.interval, radiant.bind(self, 'try_to_spawn_crab'), self.interval)
			self.__saved_variables:mark_changed()

			self:ready_to_harvest(false)
		end
		self.stupid_delay:destroy()
		self.stupid_delay = nil
	end
	self.stupid_delay = stonehearth.calendar:set_persistent_timer("ArchipelagoCrabSpawner delay", 0, delayed_function)
end

function ArchipelagoCrabSpawner:spawner_removed()
	-- log:error("spawner_removed")
	self:destroy_spawn_timer()
	if self._sv.crab then
		if self._approach_task then
			self._approach_task:destroy()
			self._approach_task = nil
		end
		self._sv.crab = nil
		self.__saved_variables:mark_changed()
	end
end

function ArchipelagoCrabSpawner:try_to_spawn_crab()
	-- log:error("try_to_spawn_crab")
	local ec = self._entity:get_component("entity_container")
	if ec then
		for id, child in ec:each_child() do
			--if it has a child (trapped) it should do nothing, just wait until it is harvested.
			return
		end
	end
	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		-- log:error("try_to_spawn_crab nil location")
		return
	end
	local cube = Cube3(location):inflated(Point3(self.radius, 1, self.radius))
	local intersected_entities = radiant.terrain.get_entities_in_cube(cube)
	local crab_counter = 0
	for id, entity in pairs(intersected_entities) do
		if entity:get_uri() == CRAB then
			crab_counter = crab_counter+1
			local approaching = self:approach_task(entity,location)
			if approaching then
				break
			end
		end
	end
	if crab_counter == 0 then
		self:spawn_crab(location)
	end
end

function ArchipelagoCrabSpawner:spawn_crab(location)
	-- log:error("spawn_crab")
	local crab = radiant.entities.create_entity(CRAB)
	radiant.entities.set_player_id(crab, "peaceful_animals")
	local far_location, found = self:find_placement_point(location, self.radius/2, self.radius)
	if found then
		radiant.terrain.place_entity_at_exact_location(crab, far_location)
		self:approach_task(crab,location)
	else
		-- log:error("Somehow the game didn't found a place to spawn the crab")
		radiant.entities.destroy_entity(crab)
	end
end

function ArchipelagoCrabSpawner:find_placement_point(location, min_radius, max_radius)
	local function random_terrain_position()
		local x,z
		local max_tries = max_radius
		repeat
			max_tries = max_tries-1
			x = rng:get_int(-max_radius,max_radius)
			z = rng:get_int(-max_radius,max_radius)
		--code aligner comment because sublime can't understand repeat until identation ¬¬
		until max_tries<0 or (not radiant.math.in_bounds(x, -min_radius,min_radius) and not radiant.math.in_bounds(z, -min_radius,min_radius) )
		--code aligner comment because sublime can't understand repeat until identation ¬¬
		if max_tries <0 then
			return false
		end

		return radiant.terrain.get_point_on_terrain(location+Point3(x,0,z))
	end

	local max_tries = max_radius
	local new_location, is_reachable
	repeat
		max_tries = max_tries-1
		new_location = random_terrain_position()
		is_reachable = new_location and (location.y - new_location.y) >= -1 and (location.y - new_location.y) <= 1
	--code aligner comment because sublime can't understand repeat until identation ¬¬
	until max_tries<0 or (new_location and is_reachable)
	--code aligner comment because sublime can't understand repeat until identation ¬¬

	if max_tries <0 then
		return false,false
	end
	return new_location, true
end

function ArchipelagoCrabSpawner:approach_task(crab,location)
	local crab_parent = radiant.entities.get_parent(crab)
	if crab_parent:get_uri() == "archipelago_biome:gizmos:crab_trap" then
		-- log:error("Crab in a trap already")
		return false
	end
	local activities = crab:get_component('stonehearth:ai'):get_active_activities()
	if activities["stonehearth:goto_entity"] then
		-- log:error("someone is already capturing it")
		return false
	end

	local crab_collar = radiant.entities.create_entity(COLLAR)
	local equipment = crab:add_component('stonehearth:equipment')
	if equipment:has_item_type(COLLAR) then
		-- log:error("someone is already capturing it")
		return false
	end
	equipment:equip_item(crab_collar)
	radiant.entities.add_buff(crab, 'stonehearth:buffs:despawn:after_day')

	self._approach_task = crab:get_component('stonehearth:ai')
	:get_task_group('archipelago_biome:task_groups:crab_movement')
	:create_task('stonehearth:goto_entity', {
		entity = self._entity
		})
	:once()
	:notify_interrupted(
		function ()
			-- log:error("notify_interrupted")
			self._approach_task = nil
			equipment:unequip_item(COLLAR)

			self._sv.crab = nil
			self.__saved_variables:mark_changed()
		end
		)
	:notify_completed(
		function ()
			-- log:error("notify_completed")
			self._approach_task = nil
			local mob = crab:add_component('mob')
			mob:set_mob_collision_type(_radiant.om.Mob.NONE)
			radiant.entities.add_child(self._entity, crab, Point3.zero)
			radiant.entities.add_buff(crab, 'stonehearth:buffs:snared')
			radiant.entities.remove_buff(crab, 'stonehearth:buffs:despawn:after_day')

			self:ready_to_harvest(true)
			stonehearth.ai:reconsider_entity(self._entity)

			self._sv.crab = nil
			self.__saved_variables:mark_changed()
		end
		)
	:start()

	self._sv.crab = crab
	self.__saved_variables:mark_changed()
	return true
end

function ArchipelagoCrabSpawner:ready_to_harvest(resume)
	local rsc = self._entity:get_component('stonehearth:renewable_resource_node')
	if rsc then
		if resume then
			rsc:renew()
		else
			rsc:pause_resource_timer()
		end
	end
end

function ArchipelagoCrabSpawner:find_nearby_water()
	local location = radiant.entities.get_world_grid_location(self._entity)
	local cube = Cube3(location):inflated(Point3(self.radius, self.radius, self.radius))
	return radiant.terrain.get_entities_in_cube(cube)
end

function ArchipelagoCrabSpawner:destroy_spawn_timer()
	-- log:error("destroy_spawn_timer")
	if self._sv.spawn_timer then
		self._sv.spawn_timer:destroy()
		self._sv.spawn_timer = nil
		self.__saved_variables:mark_changed()
	end
end

function ArchipelagoCrabSpawner:destroy()
	-- log:error("destroy")
	self:spawner_removed()
	if self._on_added_to_world_listener then
		self._on_added_to_world_listener:destroy()
		self._on_added_to_world_listener = nil
	end
	if self._on_removed_from_world_listener then
		self._on_removed_from_world_listener:destroy()
		self._on_removed_from_world_listener = nil
	end
	self:destroy_spawn_timer()
end

return ArchipelagoCrabSpawner