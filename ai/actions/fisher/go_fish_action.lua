local GoFish = class()

GoFish.name = 'go to a dock to fish'
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

function GoFish:start_thinking(ai, entity, args)
	local job_component = entity:get_component('stonehearth:job')
	local fish_table = job_component:get_curr_job_controller():chose_random_fish()
	ai:set_think_output({
		effort = fish_table.effort or 60,
		alias = fish_table.alias
		})
end

local ai = stonehearth.ai
return ai:create_compound_action(GoFish)
:execute('stonehearth:drop_carrying_now', {})
:execute('stonehearth:goto_entity_type', {
	filter_fn = ai.CALL(find_a_fishing_spot, ai.ENTITY),
	description = 'find a dock'
	})
:execute('stonehearth:reserve_entity', { entity = ai.PREV.destination_entity })
:execute('archipelago_biome:turn_to_face_water', {dock = ai.BACK(2).destination_entity})
:execute('archipelago_biome:fishing_animations', {effort = ai.BACK(5).effort})
:execute('archipelago_biome:pickup_fish', {
	dock = ai.BACK(4).destination_entity,
	fish_alias = ai.BACK(6).alias
	})
:execute('stonehearth:wait_for_closest_storage_space', { item = ai.PREV.fish })
:execute('stonehearth:drop_carrying_in_storage', {storage = ai.PREV.storage})