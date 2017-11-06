local GoFish = class()

GoFish.name = 'go to a dock to fish'
GoFish.does = 'archipelago_biome:go_fish'
GoFish.args = { }
GoFish.version = 2
GoFish.priority = 1

function find_a_fishing_spot()
	return stonehearth.ai:filter_from_key('archipelago_biome:go_fish', 'none', function(target)
		return radiant.entities.get_entity_data(target, 'archipelago_biome:fishing_spot') ~= nil
		end)
end

local ai = stonehearth.ai
return ai:create_compound_action(GoFish)
:execute('stonehearth:drop_carrying_now', {})
:execute('stonehearth:goto_entity_type', {
	filter_fn = find_a_fishing_spot(),
	description = 'find a dock'
	})
:execute('stonehearth:reserve_entity', { entity = ai.PREV.destination_entity })
:execute('archipelago_biome:fishing_animations')
:execute('archipelago_biome:pickup_fish', {location = ai.BACK(3).destination_entity})
:execute('stonehearth:wait_for_closest_storage_space', { item = ai.PREV.fish })
:execute('stonehearth:drop_carrying_in_storage', {storage = ai.PREV.storage})