local GoFish = class()

GoFish.name = 'go to a fishing_spot to fish'
GoFish.does = 'archipelago_biome:go_fish'
GoFish.status_text_key = 'archipelago_biome:ai.actions.status_text.fishing'
GoFish.args = { }
GoFish.version = 2
GoFish.priority = 1

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

local function rate_fishing_spot(entity)
	--take entity type (zone, boat or dock) and distance into consideration
	local rng = _radiant.math.get_default_rng()
	return rng:get_real(0, 1)
end

function GoFish:start_thinking(ai, entity, args)
	local job_component = entity:get_component('stonehearth:job')
	local current_loot = job_component:get_curr_job_controller():get_current_loot()
	if current_loot then
		ai:set_think_output()
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
:execute('archipelago_biome:fishing_animations', {})
:execute('archipelago_biome:pickup_fish', {dock = ai.BACK(5).item})
:execute('archipelago_biome:closest_storage_to_dock', {
	dock = ai.BACK(6).item
})
:execute('stonehearth:drop_carrying_in_storage', {storage = ai.PREV.storage})