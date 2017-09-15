local ArchipelagoCrabSpawner = class()
local Cube3 = _radiant.csg.Cube3
local Point3 = _radiant.csg.Point3
local rng = _radiant.math.get_default_rng()
local CRAB = "archipelago_biome:critters:crab"
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
		self._on_added_to_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_added_to_world', self, self.activate_the_spawner)
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
		local task = self._sv.crab:get_component('stonehearth:ai')
		:get_task_group('stonehearth:unit_control')
		:get_name()
		if task=="stonehearth:goto_entity" then
			task:destroy()
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
	local last_crab_found = nil
	for id, entity in pairs(intersected_entities) do
		if entity:get_uri() == CRAB then
			crab_counter = crab_counter+1
			last_crab_found = entity
		end
	end
	if crab_counter > 0 then
		self:approach_task(last_crab_found,location)
	else
		self:spawn_crab(location)
	end
end

function ArchipelagoCrabSpawner:spawn_crab(location)
	-- log:error("spawn_crab")
	local crab = radiant.entities.create_entity(CRAB)
	local far_location = radiant.terrain.find_placement_point(location, self.radius, self.radius, crab)
	radiant.terrain.place_entity_at_exact_location(crab, far_location)
	self:approach_task(crab,location)
end

function ArchipelagoCrabSpawner:approach_task(crab,location)
	-- log:error("approach_task")
	self._sv.crab = crab
	self.__saved_variables:mark_changed()

	local task = crab:get_component('stonehearth:ai')
	:get_task_group('stonehearth:unit_control')
	:get_name()
	if task=="stonehearth:goto_entity" then
		return --someone is already capturing it
	end

	self._approach_task = crab:get_component('stonehearth:ai')
	:get_task_group('stonehearth:unit_control')
	:create_task('stonehearth:goto_entity', {
		entity = self._entity
		})
	:set_priority(100)
	:once()
	:notify_completed(
		function ()
			self._approach_task = nil
			local mob = crab:add_component('mob')
			mob:set_mob_collision_type(_radiant.om.Mob.NONE)
			radiant.entities.add_child(self._entity, crab, Point3.zero)
			radiant.entities.add_buff(crab, 'stonehearth:buffs:snared')

			self:ready_to_harvest(true)
			stonehearth.ai:reconsider_entity(self._entity)

			self._sv.crab = nil
			self.__saved_variables:mark_changed()
		end
		)
	:start()
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