local Point3 = _radiant.csg.Point3
local ArchipelagoDock = class()

local VERSIONS = {
ZERO = 0,
DOCK_SPOT_FOR_MULTIPLAYER = 1,
SAVED_LEGS = 2
}

function ArchipelagoDock:get_version()
	return VERSIONS.SAVED_LEGS
end

function ArchipelagoDock:fixup_post_load(old_save_data)
	if old_save_data.version < VERSIONS.DOCK_SPOT_FOR_MULTIPLAYER then
		--older versions didn't have a player_id, so could endup being used by other factions
		if self._sv.dock_spot then
			radiant.entities.set_player_id(self._sv.dock_spot, self._entity:get_player_id())
		end
	end
	if old_save_data.version < VERSIONS.SAVED_LEGS then
		--buildings could split the legs from docks and leave them in the world
		local ec = self._entity:get_component("entity_container")
		if ec then
			for id, child in ec:each_child() do
				ec:remove_child(id)
				radiant.entities.destroy_entity(child)
			end
		end
	end
end

function ArchipelagoDock:initialize()
	self._sv.dock_spot = nil
	self._sv.saved_legs = {}
	self.__saved_variables:mark_changed()
end

function ArchipelagoDock:activate()
	local json = radiant.entities.get_json(self)
	self.no_legs = json.no_legs or false
	self.no_water = json.no_water or false
	self.dock_spot_offset = json.dock_spot_offset or -1

	if not self._added_to_world_listener then
		self._added_to_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_added_to_world', function()
			self:on_added_to_world()
			end)
	end
	if not self._removed_from_world_listener then
		self._removed_from_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_removed_from_world', function()
			self:remove_legs()
			self:remove_fishing_spot()
			end)
	end
	if not self._in_the_water_listener and not self.no_water then
		self._in_the_water_listener = radiant.events.listen(self._entity, 'archipelago_biome:in_the_water', function(e)
			self:add_fishing_spot(e.location)
			end)
	end
end

function ArchipelagoDock:on_added_to_world()
	local delayed_function = function ()
		--for some reason, location is nil when the on_added event fires,
		--so I have to wait 1gametick for it to be set, and it is done running inside this
		local location = radiant.entities.get_world_grid_location(self._entity)
		if location and not self.no_legs and not next(self._sv.saved_legs) then
			self:add_legs(location)
		end
		if location and self.no_water then
			self:add_fishing_spot(location)
		end
		self.stupid_delay:destroy()
		self.stupid_delay = nil
	end
	self.stupid_delay = stonehearth.calendar:set_persistent_timer("ArchipelagoDock delay", 0, delayed_function)
end

function ArchipelagoDock:_get_dock_edge(dock,location)
	local facing = radiant.entities.get_facing(dock)
	local offset = radiant.math.rotate_about_y_axis(-Point3.unit_z*2, facing):to_closest_int()
	return location + offset
end

function ArchipelagoDock:_get_dock_spot_location(dock,location)
	local facing = radiant.entities.get_facing(dock)
	local offset = radiant.math.rotate_about_y_axis(Point3(0,0,self.dock_spot_offset), facing):to_closest_int()
	return location + offset
end

function ArchipelagoDock:get_bottom()
	local location = radiant.entities.get_world_grid_location(self._entity)
	local edge = self:_get_dock_edge(self._entity,location)
	local edge_offset = edge - Point3.unit_y
	local bottom_position = edge
	while not radiant.terrain.is_blocked(edge_offset) and edge_offset.y>0 do
		bottom_position = edge_offset
		edge_offset = edge_offset - Point3.unit_y
	end
	return radiant.terrain.get_entities_at_point(bottom_position)
end

function ArchipelagoDock:add_fishing_spot(location)
	self:remove_fishing_spot()
	self._sv.dock_spot = radiant.entities.create_entity("archipelago_biome:decoration:dock_spot",
		{owner = self._entity:get_player_id()})
	radiant.terrain.place_entity_at_exact_location(self._sv.dock_spot,
		self:_get_dock_spot_location(self._entity,location) +Point3.unit_y)
	local facing = radiant.entities.get_facing(self._entity)
	radiant.entities.turn_to(self._sv.dock_spot, facing)
	self.__saved_variables:mark_changed()
end

function ArchipelagoDock:remove_fishing_spot()
	if self._sv.dock_spot then
		radiant.entities.destroy_entity(self._sv.dock_spot)
		self._sv.dock_spot = nil
	end
	self.__saved_variables:mark_changed()
end

function ArchipelagoDock:add_legs(location)
	local edge = self:_get_dock_edge(self._entity,location)
	local edge_offset = edge - Point3.unit_y
	while not radiant.terrain.is_blocked(edge_offset) and edge_offset.y >0 do
		--todo: allow other leg types, and random types
		local leg = radiant.entities.create_entity("archipelago_biome:decoration:dock_leg",
			{owner = self._entity:get_player_id()})
		table.insert(self._sv.saved_legs, leg)
		radiant.terrain.place_entity_at_exact_location(leg, edge_offset)
		local facing = radiant.entities.get_facing(self._entity)
		radiant.entities.turn_to(leg, facing)
		edge_offset = edge_offset - Point3.unit_y
	end
	self.__saved_variables:mark_changed()
end

function ArchipelagoDock:remove_legs()
	for i,v in ipairs(self._sv.saved_legs) do
		radiant.entities.destroy_entity(v)
	end
	self._sv.saved_legs = {}
	self.__saved_variables:mark_changed()
end

function ArchipelagoDock:destroy()
	self:remove_legs()
	self:remove_fishing_spot()
	if self._added_to_world_listener then
		self._added_to_world_listener:destroy()
		self._added_to_world_listener = nil
	end
	if self._removed_from_world_listener then
		self._removed_from_world_listener:destroy()
		self._removed_from_world_listener = nil
	end
	if self._in_the_water_listener then
		self._in_the_water_listener:destroy()
		self._in_the_water_listener = nil
	end
end

return ArchipelagoDock