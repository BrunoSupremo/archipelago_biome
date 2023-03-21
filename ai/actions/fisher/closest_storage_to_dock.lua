local Entity = _radiant.om.Entity

local WaitForClosestStorageSpace = radiant.class()
WaitForClosestStorageSpace.name = 'wait for closest storage space to a dock'
WaitForClosestStorageSpace.does = 'archipelago_biome:closest_storage_to_dock'
WaitForClosestStorageSpace.args = {
	dock = Entity
}
WaitForClosestStorageSpace.think_output = {
	storage = Entity
}
WaitForClosestStorageSpace.priority = 0

function WaitForClosestStorageSpace:start_thinking(ai, entity, args)
	local job_component = entity:get_component('stonehearth:job')
	local current_loot = job_component:get_curr_job_controller():get_current_loot()

	local storage = stonehearth.inventory:get_inventory(radiant.entities.get_player_id(entity))
	:get_all_public_storage()

	local shortest_distance
	local closest_storage

	--Iterate through the stockpiles. If we match the stockpile criteria AND there is room
	--check if the stockpile is the closest such stockpile to the dock
	for id, storage_entity in pairs(storage) do
		local storage_component = storage_entity:get_component('stonehearth:storage')
		if not storage_component:is_full() and storage_component:passes(current_loot.entity) then
			local distance_between = radiant.entities.distance_between(args.dock, storage_entity)
			
			-- prefer racks
			if storage_entity:get_uri() == 'archipelago_biome:containers:input_fish_rack' then
				distance_between = distance_between / 1.333
			end

			if not closest_storage or distance_between < shortest_distance then
				closest_storage = storage_entity
				shortest_distance = distance_between
			end
		end
	end

	--If there is a closest storage, return it
	if closest_storage then
		ai:set_think_output({
			storage = closest_storage
		})
	end
end

return WaitForClosestStorageSpace