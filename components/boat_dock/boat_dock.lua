local Point3 = _radiant.csg.Point3
local Region3 = _radiant.csg.Region3
local Cube3 = _radiant.csg.Cube3
local ArchipelagoBoatDock = class()

local VERSIONS = {
	ZERO = 0
}

function ArchipelagoBoatDock:get_version()
	return VERSIONS.ZERO
end

function ArchipelagoBoatDock:fixup_post_load(old_save_data)

end

function ArchipelagoBoatDock:initialize()
	self._sv.platform = nil
	self._sv.other_dock = nil
	self._sv._effect_overlay = nil
end

function ArchipelagoBoatDock:activate()
	if not self._removed_from_world_listener then
		self._removed_from_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_removed_from_world', function()
			self:destroy_platform()
			self:destroy_other_dock()
			if self._sv._effect_overlay then
				self._sv._effect_overlay:stop()
				self._sv._effect_overlay = nil
			end
		end)
	end
	if not self._in_the_water_listener then
		self._in_the_water_listener = radiant.events.listen(self._entity, 'archipelago_biome:in_the_water', function(e)
			self:create_connections()
		end)
	end
	self:_trace_sensor()
end

function ArchipelagoBoatDock:get_water_entity()
	local location = radiant.entities.get_world_grid_location(self._entity)
	local region = Region3()
	region:add_point(location)
	region = region:inflated(Point3(3,3,3))
	return radiant.terrain.get_entities_in_region(region)
end

function ArchipelagoBoatDock:create_connections()
	if not self._sv.platform then
		local other_side = self:find_other_side()
		if other_side then
			self:create_platform(other_side)
			self:create_destination_dock(other_side)
		else
			self._sv._effect_overlay = radiant.effects.run_effect(self._entity, "archipelago_biome:effects:overlay:no_connection", nil, nil, { playerColor = radiant.entities.get_player_color(self._entity) })
		end
	end
end

function ArchipelagoBoatDock:find_other_side()
	local mob = self._entity:get_component('mob')
	local facing = mob:get_facing()
	local edge = mob:get_world_grid_location()
	local front_block = radiant.math.rotate_about_y_axis(-Point3.unit_z, facing):to_closest_int()
	local edge_offset = edge + front_block
	local ending_block = edge

	local water_offset = 0
	for i=0,10 do
		local found_water = false
		local intersected_entities = radiant.terrain.get_entities_at_point(edge -Point3(0,i,0))
		for dummy, maybe_water in pairs(intersected_entities) do
			local water_component = maybe_water:get_component('stonehearth:water')
			if water_component then
				found_water = true
				water_offset = i
				break
			end
		end
		if found_water then
			break
		end
	end

	while not radiant.terrain.is_blocked(edge_offset) and not radiant.terrain.is_blocked(edge_offset -Point3(0,water_offset,0)) do
		if not radiant.terrain.in_bounds(edge_offset) then
			return false --got outside of the map
		end
		ending_block = edge_offset
		edge_offset = edge_offset + front_block
	end

	if radiant.terrain.in_bounds(edge_offset) then
		return ending_block
	end
end

function ArchipelagoBoatDock:create_platform(other_side)
	local location = radiant.entities.get_world_grid_location(self._entity)
	self._sv.platform = radiant.entities.create_entity("archipelago_biome:gizmos:boat_dock_platform")
	radiant.terrain.place_entity_at_exact_location(self._sv.platform, location + Point3.unit_y)

	local rcs = self._sv.platform:get_component('region_collision_shape')
	rcs:set_region(_radiant.sim.alloc_region3())
	local x_size, z_size = other_side.x - location.x, other_side.z - location.z
	local p_min, p_max = radiant.math.get_min_max(Point3(0,0,0), Point3(x_size, 1, z_size))
	if p_min.x == p_max.x then
		p_max.x = 1
		p_min.z = p_min.z+1
	end
	if p_min.z == p_max.z then
		p_max.z = 1
		p_min.x = p_min.x+1
	end
	rcs:get_region():modify(function(cursor)
		cursor:clear()
		cursor:add_unique_cube(
			Cube3(p_min, p_max)
			)
	end)
end

function ArchipelagoBoatDock:create_destination_dock(other_side)
	self._sv.other_dock = radiant.entities.create_entity("archipelago_biome:gizmos:boat_dock")
	local facing = radiant.entities.get_facing(self._entity)
	radiant.entities.turn_to(self._sv.other_dock, facing+180)

	local other_dock_component = self._sv.other_dock:get_component("archipelago_biome:boat_dock")
	other_dock_component._sv.platform = self._sv.platform
	other_dock_component._sv.other_dock = self._entity

	radiant.terrain.place_entity_at_exact_location(self._sv.other_dock, other_side, {force_iconic = false})
end

function ArchipelagoBoatDock:destroy_platform()
	if self._sv.platform and self._sv.platform:is_valid() then
		radiant.entities.destroy_entity(self._sv.platform)
		self._sv.platform = nil
	end
end

function ArchipelagoBoatDock:destroy_other_dock()
	if self._sv.other_dock and self._sv.other_dock:is_valid() then
		--first remove itself from the other dock so it doesn't try to destroy us together with it
		local other_dock_component = self._sv.other_dock:get_component("archipelago_biome:boat_dock")
		other_dock_component._sv.other_dock = nil

		radiant.entities.destroy_entity(self._sv.other_dock)
		self._sv.other_dock = nil
	end
end

function ArchipelagoBoatDock:destroy()
	self:destroy_platform()
	self:destroy_other_dock()

	if self._sensor_trace then
		self._sensor_trace:destroy()
		self._sensor_trace = nil
	end
	if self._removed_from_world_listener then
		self._removed_from_world_listener:destroy()
		self._removed_from_world_listener = nil
	end
	if self._in_the_water_listener then
		self._in_the_water_listener:destroy()
		self._in_the_water_listener = nil
	end
	if self._sv._effect_overlay then
		self._sv._effect_overlay:stop()
		self._sv._effect_overlay = nil
	end
end

function ArchipelagoBoatDock:_trace_sensor()
	local sensor_list = self._entity:get_component('sensor_list')
	local sensor = sensor_list:get_sensor("dock_sensor")
	if sensor then
		self._sensor_trace = sensor:trace_contents('boat_dock')
		:on_added(function (id, entity)
			self:_on_added_to_sensor(id, entity)
		end)
		:on_removed(function (id)
			self:_on_removed_to_sensor(id)
		end)
		:push_object_state()
	end
end

function ArchipelagoBoatDock:_on_added_to_sensor(id, entity)
	if self:_valid_entity(entity) then
		local entity_container = entity:get_component('entity_container')
		if entity_container then
			for child_id, child in entity_container:each_attached_item() do
				if child:get_uri() == "archipelago_biome:gizmos:boat" then
					entity_container:remove_child(child_id)
					radiant.entities.destroy_entity(child)
				end
			end
		end

		local mob = entity:add_component('mob')
		mob:set_model_origin(Point3.zero)
		
		radiant.entities.remove_buff(entity, "archipelago_biome:buffs:boat")
	end
end

function ArchipelagoBoatDock:_customize_boat(boat, boat_owner)
	local boat_render_info = boat:get_component('render_info')
	--model
	local player_id = radiant.entities.get_player_id(boat_owner)
	if player_id and stonehearth.player:get_kingdom(player_id) then
		boat_render_info:set_model_variant(stonehearth.player:get_kingdom(player_id))
	end
	--size
	local custom_size = boat_owner:get_component("render_info"):get_scale()
	custom_size = (custom_size + 0.2)/2
	boat_render_info:set_scale(custom_size)
end

function ArchipelagoBoatDock:_on_removed_to_sensor(id)
	local entity = radiant.entities.get_entity(id)
	if self:_valid_entity(entity) then
		local location = radiant.entities.get_world_grid_location(entity)
		if not radiant.terrain.is_blocked(location - Point3.unit_y) then
			local boat = radiant.entities.create_entity("archipelago_biome:gizmos:boat")
			self:_customize_boat(boat, entity)
			entity:add_component('entity_container'):add_child_to_bone(boat, 'cant_believe_this_worked')
			radiant.entities.move_to_grid_aligned(boat, Point3.zero)

			for i=1,10 do
				local found_water = false
				local intersected_entities = radiant.terrain.get_entities_at_point(location -Point3(0,i,0))
				for dummy, maybe_water in pairs(intersected_entities) do
					local water_component = maybe_water:get_component('stonehearth:water')
					if water_component then
						found_water = true
						local mob = entity:add_component('mob')
						mob:set_model_origin(Point3(0, i - water_component:get_top_layer_height(), 0))
						break
					end
				end
				if found_water then
					break
				end
			end

			radiant.entities.add_buff(entity, "archipelago_biome:buffs:boat")
		end
	end
end

function ArchipelagoBoatDock:_valid_entity(entity)
	if not entity then
		return false
	end
	if not radiant.entities.has_free_will(entity) then
		return false
	end
	return true
end

return ArchipelagoBoatDock