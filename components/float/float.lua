local Point3 = _radiant.csg.Point3
local ArchipelagoFloat = class()
-- local log = radiant.log.create_logger('meu_log')

function ArchipelagoFloat:activate()
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

function ArchipelagoFloat:destroy()
	if self._added_to_world_listener then
		self._added_to_world_listener:destroy()
		self._added_to_world_listener = nil
	end
end

return ArchipelagoFloat