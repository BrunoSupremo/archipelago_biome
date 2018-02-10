local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3
local ArchipelagoNeedWater = class()
-- local log = radiant.log.create_logger('need_water')

function ArchipelagoNeedWater:initialize()
	self._sv._effect_overlay = nil
	self._sv._current_animation = nil
end

function ArchipelagoNeedWater:activate()
	-- log:error("activate")
	local json = radiant.entities.get_json(self)
	self.need_water_icon = json.need_water_icon
	self.water_location_function = json.water_location_function
	self.float = json.float
	if self.float and self.float.add_animation then
		self._ground_animation = self.float.add_animation.at_ground
		self._water_animation = self.float.add_animation.at_water
	end

	if not self._added_to_world_listener then
		self._added_to_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_added_to_world', function()
			-- log:error("_added_to_world_listener")
			self:resource_timer(false)
			self:on_added_to_world()
			end)
	end
	if not self._removed_from_world_listener then
		self._removed_from_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_removed_from_world', function()
			-- log:error("_removed_from_world_listener")
			self:on_removed_from_world()
			end)
	end
	if not self._in_the_water_listener then
		self._in_the_water_listener = radiant.events.listen(self._entity, 'archipelago_biome:in_the_water', function(e)
			-- log:error("_in_the_water_listener")
			self:resource_timer(true)
			self:float_now(e.water_level, e.location)
			end)
	end
end

function ArchipelagoNeedWater:float_now(water_level, location)
	-- log:error("float_now")
	if not self.float then return end

	local add_height = self.float.add_height or 0
	local new_y = water_level + add_height
	location.y = math.max(location.y, new_y)
	radiant.entities.move_to(self._entity, location)
	self._entity:add_component('mob'):set_ignore_gravity(true)
end

function ArchipelagoNeedWater:on_removed_from_world()
	-- log:error("on_removed_from_world")
	self:_stop_current_animation()

	if self._sv._effect_overlay then
		self._sv._effect_overlay:stop()
		self._sv._effect_overlay = nil
		self.__saved_variables:mark_changed()
	end
end

function ArchipelagoNeedWater:on_added_to_world()
	-- log:error("on_added_to_world")
	local delayed_function = function ()
		--for some reason, location is nil when the on_added event fires,
		--so I have to wait 1gametick for it to be set, and it is done running inside this
		local location = radiant.entities.get_world_grid_location(self._entity)
		if location then
			local intersected_entities
			if self.water_location_function then
				local component = self._entity:get_component(self.water_location_function.component)
				local fn = self.water_location_function.fn

				local water_location = component[fn](component)
				intersected_entities = radiant.terrain.get_entities_at_point(water_location)
			else
				intersected_entities = radiant.terrain.get_entities_at_point(location)
			end

			local in_the_water = false
			for id, entity in pairs(intersected_entities) do
				local water_component = entity:get_component('stonehearth:water')
				if water_component then
					radiant.events.trigger(self._entity, 'archipelago_biome:in_the_water', {water_level = water_component:get_water_level(), location = location})
					in_the_water = true
					break
				end
			end
			if self.need_water_icon and not in_the_water then
				self._sv._effect_overlay = radiant.effects.run_effect(self._entity, "archipelago_biome:effects:no_water_overlay", nil, nil, { playerColor = radiant.entities.get_player_color(self._entity) })
				self.__saved_variables:mark_changed()
			end
			self:run_animation(in_the_water)
		else
			-- log:error("on_added_to_world nil location")
		end
		self.stupid_delay:destroy()
		self.stupid_delay = nil
	end
	self.stupid_delay = stonehearth.calendar:set_persistent_timer("ArchipelagoNeedWater delay", 0, delayed_function)
end

function ArchipelagoNeedWater:resource_timer(resume)
	local rsc = self._entity:get_component('stonehearth:renewable_resource_node')
	if rsc then
		if resume then
			-- log:error("resume")
			rsc:resume_resource_timer()
		else
			-- log:error("pause")
			rsc:pause_resource_timer()
		end
	end
end

function ArchipelagoNeedWater:run_animation(in_the_water)
	-- log:error("run_animation")
	if in_the_water then
		-- log:error("_water_animation")
		if self._water_animation then
			self._sv._current_animation = radiant.effects.run_effect(self._entity, self._water_animation):set_cleanup_on_finish(false)
			self.__saved_variables:mark_changed()
		end
	else
		-- log:error("_ground_animation")
		if self._ground_animation then
			self._sv._current_animation = radiant.effects.run_effect(self._entity, self._ground_animation):set_cleanup_on_finish(false)
			self.__saved_variables:mark_changed()
		end
	end
end

function ArchipelagoNeedWater:_stop_current_animation()
	-- log:error("_stop_current_animation")
	if self._sv._current_animation then
		self._sv._current_animation:stop()
		self._sv._current_animation = nil
		self.__saved_variables:mark_changed()
	end
end

function ArchipelagoNeedWater:destroy()
	-- log:error("destroy")
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
	if self._sv._effect_overlay then
		self._sv._effect_overlay:stop()
		self._sv._effect_overlay = nil
	end
	self:_stop_current_animation()
	self.__saved_variables:mark_changed()
end

return ArchipelagoNeedWater