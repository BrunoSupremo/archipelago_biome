local Point3 = _radiant.csg.Point3
local ArchipelagoFloat = class()
-- local log = radiant.log.create_logger('meu_log')

function ArchipelagoFloat:activate()
	local json = radiant.entities.get_json(self)
	if json and json.add_animation then
		self._ground_animation = json.add_animation.at_ground
		self._water_animation = json.add_animation.at_water
	end
	if not self._added_to_world_listener then
		-- log:error('_added_to_world_listener created')
		self._added_to_world_listener = radiant.events.listen_once(self._entity, 'stonehearth:on_added_to_world', function()
			-- log:error('_added_to_world_listener triggered')
			self._added_to_world_listener = nil
			self:on_added_to_world()
			end)
	end
end

function ArchipelagoFloat:on_added_to_world()
	local float_callback = function ()
		--bla
		-- log:error('timer activated')
		self:_reset_animation()

		local location = radiant.entities.get_world_grid_location(self._entity)
		local intersected_entities = radiant.terrain.get_entities_at_point(location)

		for id, entity in pairs(intersected_entities) do
			local water_component = entity:get_component('stonehearth:water')
			if water_component then
				-- log:error('object is in the water')

				local water_level = water_component:get_water_level()
				local json = radiant.entities.get_json(self)
				local add_height = json.add_height or 0
				local new_y = math.floor(water_level) + add_height
				location.y = math.max(location.y, new_y)
				-- log:error('float location %s', location.y)
				radiant.terrain.place_entity_at_exact_location(self._entity, location, {force_iconic = false})
				self._entity:add_component('mob'):set_ignore_gravity(true)
				self:_apply_water_animation()

				break
			end
		end
		self.float_timer = nil
		-- log:error('setting listener again')
		self._added_to_world_listener = radiant.events.listen_once(self._entity, 'stonehearth:on_added_to_world', function()
			-- log:error('listener triggered again')
			self._added_to_world_listener = nil
			self:on_added_to_world()
			end)
	end
	-- log:error('timer set')
	self.float_timer = stonehearth.calendar:set_persistent_timer("FloatComponent float_callback", 0, float_callback)
end

function ArchipelagoFloat:_reset_animation()
	if self._current_animation then
		self._current_animation:stop()
		self._current_animation = nil
	end
	if self._ground_animation then
		self._current_animation = radiant.effects.run_effect(self._entity, self._ground_animation):set_cleanup_on_finish(false)
	end
end

function ArchipelagoFloat:_apply_water_animation()
	if self._water_animation then
		self._current_animation = radiant.effects.run_effect(self._entity, self._water_animation):set_cleanup_on_finish(false)
	end
end

function ArchipelagoFloat:destroy()
	if self._added_to_world_listener then
		self._added_to_world_listener:destroy()
		self._added_to_world_listener = nil
	end

	if self._current_animation then
		self._current_animation:stop()
		self._current_animation = nil
	end
end

return ArchipelagoFloat