local Color4 = _radiant.csg.Color4
local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3

local validator = radiant.validator

local FishingCallHandler = class()

function FishingCallHandler._custom_is_valid_location(self_variable, brick)
	--i had to hack into this stupid function because it was the only way to make it work 😡
	if not brick then
		return false
	end

	if radiant.terrain.is_blocked(brick) then
		return false
	end
	if not radiant.terrain.is_supported(brick) then
		return false
	end
	local entities = radiant.terrain.get_entities_at_point(brick)
	for _, entity in pairs(entities) do
		local water_component = entity:get_component('stonehearth:water')
		if water_component and water_component:get_data().height>1 then
			-- :get_data() and then you have the contents of ._sv - thanks for the tip Paul
			return false
		end
		if not self_variable._can_contain_entity_filter_fn(entity, self_variable) then
			return false
		end
	end
	return FishingCallHandler.has_water_below(brick)
end

function FishingCallHandler:choose_new_fish_location(session, response)
	stonehearth.selection:select_xz_region("fish_zone")
	:use_designation_marquee(Color4(100, 150, 200, 255))
	:set_cursor('archipelago_biome:cursors:zone_fish')
	:set_invalid_cursor('archipelago_biome:cursors:zone_fish_invalid')
	:require_unblocked(true)
	:require_supported(true)
	:allow_unselectable_support_entities(true)
	:set_can_contain_entity_filter(function(entity)
		if radiant.entities.get_entity_data(entity, 'stonehearth:designation') then
			return false
		end
		if entity:get_component('terrain') then
			return false
		end
		return true
	end)
	:set_find_support_filter(function(result, select_xz_region)
		select_xz_region._is_valid_location = FishingCallHandler._custom_is_valid_location

		local entity = result.entity
		if not entity then
			return stonehearth.selection.FILTER_IGNORE
		end
		local rcs = entity:get_component('region_collision_shape')
		local region_collision_type = rcs and rcs:get_region_collision_type()
		if region_collision_type == _radiant.om.RegionCollisionShape.NONE then
			return stonehearth.selection.FILTER_IGNORE
		end

		if result.brick then
			return true
		end
		return stonehearth.selection.FILTER_IGNORE
	end)

	:done(function(selector, box)
		local size = {
			x = box.max.x - box.min.x,
			y = box.max.z - box.min.z,
		}
		_radiant.call('archipelago_biome:create_new_field', box.min, size)
		:done(function(r)
			response:resolve({ field = r.field })
		end)
		:always(function()
			selector:destroy()
		end)
	end)
	:fail(function(selector)
		selector:destroy()
		response:reject('no region')
	end)
	:go()
end

function FishingCallHandler.has_water_below(origin)
	return
	FishingCallHandler._get_water_below(origin-Point3.unit_z) or
	FishingCallHandler._get_water_below(origin+Point3.unit_z) or
	FishingCallHandler._get_water_below(origin-Point3.unit_x) or
	FishingCallHandler._get_water_below(origin+Point3.unit_x)
end

function FishingCallHandler._get_water_below(neighbor_point)
	local ground_point = radiant.terrain.get_standable_point(neighbor_point)
	local entities_present = radiant.terrain.get_entities_at_point(ground_point)

	for id, entity in pairs(entities_present) do
		local water_component = entity:get_component('stonehearth:water')
		if water_component then
			return true
		end
	end
	return false
end

function FishingCallHandler:create_new_field(session, response, location, size)
	validator.expect_argument_types({'Point3', 'table'}, location, size)

	local entity = radiant.entities.create_entity('archipelago_biome:fisher:field', { owner = session.player_id })
	radiant.terrain.place_entity(entity, location)

	local shape = Cube3(Point3.zero, Point3(size.x, 1, size.y))
	entity:add_component('region_collision_shape')
	:set_region_collision_type(_radiant.om.RegionCollisionShape.NONE)
	:set_region(_radiant.sim.alloc_region3())
	:get_region():modify(function(cursor)
		cursor:add_unique_cube(shape)
	end)
	entity:add_component('destination')
	:set_region(_radiant.sim.alloc_region3())
	:get_region():modify(function(cursor)
		cursor:add_unique_cube(shape)
	end)
	entity:get_component('destination')
	:set_adjacent(_radiant.sim.alloc_region3())
	:get_adjacent():modify(function(cursor)
		cursor:add_unique_cube(shape)
	end)

	local fisher_field = entity:get_component('archipelago_biome:fisher_field')
	fisher_field:set_size(size.x,size.y)

	return { field = entity }
end

return FishingCallHandler