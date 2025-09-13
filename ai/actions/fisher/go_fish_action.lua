local GoFish = class()

GoFish.name = 'go to a fishing_spot to fish'
GoFish.does = 'archipelago_biome:go_fish'
GoFish.status_text_key = 'archipelago_biome:ai.actions.status_text.fishing'
GoFish.args = { }
GoFish.version = 2
GoFish.priority = 1

GoFish.think_output = {
	current_loot = 'table',
	current_loot_effort = 'number'
}

function find_a_fishing_spot(ai_entity)
	local player_id = ai_entity:get_player_id()
	return stonehearth.ai:filter_from_key('archipelago_biome:go_fish', player_id,
		function(target)
			if target:get_player_id() ~= player_id then
				return false
			end
			return radiant.entities.get_entity_data(target, 'archipelago_biome:fishing_spot') ~= nil
		end
		)
end

local fisher = nil
local function rate_fishing_spot(entity)
	--distance * rng, means results are random but biased to closer locations
	local spot_location = radiant.entities.get_world_grid_location(entity)
	local fisher_location = radiant.entities.get_world_grid_location(fisher)
	local rng = _radiant.math.get_default_rng()
	return -spot_location:distance_to_squared(fisher_location) * rng:get_real(0, 1)
end

function GoFish:start_thinking(ai, entity, args)
	fisher = entity
	local fisher_job = entity:get_component('stonehearth:job'):get_curr_job_controller()
	local the_loot = fisher_job:get_current_loot()
	if the_loot then
		local effort = the_loot.data.effort or 60
		if type(effort) == 'table' then
			effort = effort["level_"..fisher_job:get_job_level()]
		end
		ai:set_think_output({
			current_loot = the_loot,
			current_loot_effort = effort
		})
	end
end

local ai = stonehearth.ai
return ai:create_compound_action(GoFish)
:execute('stonehearth:drop_carrying_now', {})
:execute('stonehearth:find_best_reachable_entity_by_type', {
	filter_fn = ai.CALL(find_a_fishing_spot, ai.ENTITY),
	rating_fn = rate_fishing_spot,
	description = 'find a fishing_spot'
})
:execute('stonehearth:goto_entity', {
	entity = ai.PREV.item
})
:execute('stonehearth:reserve_entity', { entity = ai.BACK(2).item })
:execute('archipelago_biome:turn_to_face_water', {dock = ai.BACK(3).item})
:execute('archipelago_biome:fishing_animations', {current_loot_effort = ai.BACK(6).current_loot_effort})
:execute('archipelago_biome:pickup_fish', {
	dock = ai.BACK(5).item,
	current_loot_entity = ai.BACK(7).current_loot.entity
})
:execute('archipelago_biome:closest_storage_to_dock', {
	dock = ai.BACK(6).item,
	current_loot_entity = ai.BACK(8).current_loot.entity
})
:execute('stonehearth:drop_carrying_in_storage', {storage = ai.PREV.storage})