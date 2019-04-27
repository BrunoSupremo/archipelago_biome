local GetCrab = class()

GetCrab.name = 'get a crab'
GetCrab.does = 'archipelago_biome:get_crab'
GetCrab.args = { }
GetCrab.version = 2
GetCrab.priority = 1

function make_is_available_crab_fn(ai_entity)
   local player_id = ai_entity:get_player_id()

   return stonehearth.ai:filter_from_key('archipelago_biome:get_crab', player_id, 
      function(target)
         if target:get_player_id() ~= player_id then
            return false
         end
         local crab_spawner = target:get_component('archipelago_biome:crab_spawner')
         if crab_spawner then
            return crab_spawner:harvestable()
         end
         return false
      end
      )
end

local ai = stonehearth.ai
return ai:create_compound_action(GetCrab)
:execute('stonehearth:drop_carrying_now', {})
:execute('stonehearth:goto_entity_type', {
   filter_fn = ai.CALL(make_is_available_crab_fn, ai.ENTITY),
   description = 'get a crab'
})
:execute('stonehearth:reserve_entity', { entity = ai.PREV.destination_entity })
:execute('archipelago_biome:get_crab_adjacent', { trap = ai.PREV.entity })