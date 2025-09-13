local ArchipelagoRenewableResourceNodeComponent = class()
local HARVEST_ACTION = 'stonehearth:harvest_renewable_resource'
local Point3 = _radiant.csg.Point3
local Region3 = _radiant.csg.Region3

-- added the check for climbables
function ArchipelagoRenewableResourceNodeComponent:request_harvest(player_id)
	if not self:is_harvestable() then
		return false
	end

	local json = self._json

	if json.check_owner and not radiant.entities.is_neutral_animal(self._entity:get_player_id()) and radiant.entities.is_owned_by_another_player(self._entity, player_id) then
		return false
	end

	if json.climb_to_harvest then
		self:make_climbable_first()
	end

	local task_tracker_component = self._entity:add_component('stonehearth:task_tracker')
	if task_tracker_component:is_activity_requested(HARVEST_ACTION) then
		return false
	end

	local category = json.category or 'harvest'
	local success = task_tracker_component:request_task(player_id, category, HARVEST_ACTION, json.harvest_overlay_effect)
	return success
end

function ArchipelagoRenewableResourceNodeComponent:make_climbable_first()
	self._is_climbable = true

	local region_collision_shape = self._entity:get_component('region_collision_shape')
	region_collision_shape:set_region_collision_type(_radiant.om.RegionCollisionShape.PLATFORM)

	local movement_modifier_shape = self._entity:add_component('movement_modifier_shape')
	movement_modifier_shape:set_region(_radiant.sim.alloc_region3())
	movement_modifier_shape:set_modifier(-0.5)
	movement_modifier_shape:set_nav_preference_modifier(-0.5)
	movement_modifier_shape:get_region():modify(function(cursor)
		cursor:copy_region(region_collision_shape:get_region():get())
	end)

	local vertical_pathing_region = self._entity:add_component('vertical_pathing_region')
	vertical_pathing_region:set_region(_radiant.sim.alloc_region3())
	vertical_pathing_region:get_region():modify(function(cursor)
		cursor:add_region(region_collision_shape:get_region():get())
		local bounds = region_collision_shape:get_region():get():get_bounds()
		bounds.min.y = bounds.max.y -4
		--they need this adjacent area to step out and back again (even if for a frame)
		--it is something weird with ai and ladders, they got stuck at top without this
		cursor:add_region(Region3(bounds:inflated(Point3(1, 0, 1))))
	end)

	--this is the secret, just make the destination be on top most block
	local destination = self._entity:add_component('destination')
	destination:set_adjacent(_radiant.sim.alloc_region3())
	destination:get_adjacent():modify(function(cursor)
		local bounds = region_collision_shape:get_region():get():get_bounds()
		bounds.min.y = bounds.max.y -1
		cursor:copy_region(Region3(bounds))
	end)
end

function ArchipelagoRenewableResourceNodeComponent:_cancel_harvest_request()
	local task_tracker_component = self._entity:get_component('stonehearth:task_tracker')
	if task_tracker_component and task_tracker_component:is_activity_requested(HARVEST_ACTION) then
		task_tracker_component:cancel_current_task(true)
	end
	if self._is_climbable then
		--revert the damage, so they can interact at the base again
		local destination = self._entity:get_component('destination')
		destination:set_auto_update_adjacent(true)
	end
end

return ArchipelagoRenewableResourceNodeComponent