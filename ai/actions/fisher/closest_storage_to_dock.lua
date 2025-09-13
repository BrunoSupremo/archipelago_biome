local Entity = _radiant.om.Entity

local FishingWaitForClosestStorageSpace = radiant.class()
FishingWaitForClosestStorageSpace.name = 'wait for closest storage space to a dock'
FishingWaitForClosestStorageSpace.does = 'archipelago_biome:closest_storage_to_dock'
FishingWaitForClosestStorageSpace.args = {
	dock = Entity,
	current_loot_entity = Entity
}
FishingWaitForClosestStorageSpace.think_output = {
	storage = Entity
}
FishingWaitForClosestStorageSpace.priority = 0

function FishingWaitForClosestStorageSpace:start_thinking(ai, entity, args)
	local current_loot_entity = args.current_loot_entity
	local entity_forms = current_loot_entity:get_component('stonehearth:entity_forms')
	if entity_forms then
		local iconic_entity = entity_forms:get_iconic_entity()
		if iconic_entity then
			current_loot_entity = iconic_entity
		end
	end

	local storage = stonehearth.inventory:get_inventory(radiant.entities.get_player_id(entity))
	:get_all_public_storage()

	local shortest_distance
	local closest_storage

	--Iterate through the stockpiles. If we match the stockpile criteria AND there is room
	--check if the stockpile is the closest such stockpile to the dock
	for id, storage_entity in pairs(storage) do
		local storage_component = storage_entity:get_component('stonehearth:storage')
		if not storage_component:is_full() and storage_component:passes(current_loot_entity) then
			local distance_between = radiant.entities.distance_between(args.dock, storage_entity)
			
			-- prefer racks
			if storage_entity:get_uri() == 'archipelago_biome:containers:input_fish_rack' then
				distance_between = distance_between * 0.75
			end

			if not closest_storage or distance_between < shortest_distance then
				closest_storage = storage_entity
				shortest_distance = distance_between

				if shortest_distance < 10 then
					break
				end
			end
		end
	end

	--If there is a closest storage, return it
	if closest_storage then
		ai:set_think_output({
			storage = closest_storage
		})
	else
		--if no storage was picked, check if it is because of a bad item
		if stonehearth.catalog:get_catalog_data(current_loot_entity:get_uri()).category == "uncategorized" then
			local fisher_job = entity:get_component('stonehearth:job'):get_curr_job_controller()
			print("⚫ Somehow, "..current_loot_entity:get_uri().." appeared as fishing loot. Please warn the devs.")
			fisher_job:destroy_current_loot()
			fisher_job:prepare_next_fish_loot()
			ai:reject()
		end
	end
end

return FishingWaitForClosestStorageSpace