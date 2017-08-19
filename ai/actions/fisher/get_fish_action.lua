local GetFish = class()

GetFish.name = 'get a fish'
GetFish.does = 'archipelago_biome:get_fish'
GetFish.args = { }
GetFish.version = 2
GetFish.priority = 1

function make_is_available_fish_fn()
   return stonehearth.ai:filter_from_key('archipelago_biome:get_fish', 'none', function(target)
         return radiant.entities.get_entity_data(target, 'archipelago_biome:fish') ~= nil
      end)
end

local ai = stonehearth.ai
return ai:create_compound_action(GetFish)
         :execute('stonehearth:drop_carrying_now', {})
         :execute('stonehearth:goto_entity_type', {
            filter_fn = make_is_available_fish_fn(),
            description = 'get a fish'
         })
         :execute('stonehearth:reserve_entity', { entity = ai.PREV.destination_entity })
         :execute('stonehearth:add_buff', {buff = 'stonehearth:buffs:stopped', target = ai.PREV.entity})
         :execute('stonehearth:harvest_resource_node_adjacent', { node = ai.PREV.target })
