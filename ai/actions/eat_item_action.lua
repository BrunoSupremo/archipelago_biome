local Entity = _radiant.om.Entity

local EatItem = radiant.class()
EatItem.name = 'eat item'
EatItem.does = 'stonehearth:eat_item'
EatItem.args = {
   food = Entity,
}
EatItem.priority = 0

local log = radiant.log.create_logger('eat_item_action')

function EatItem:run(ai, entity, args)
   local food = args.food

   self._food_data = self:_get_food_data(food, entity)
   if not self._food_data then
      ai:abort(string.format('Cannot eat: No food data for %s.', tostring(food)))
   end

   ai:set_status_text_key('stonehearth:ai.actions.status_text.eat_item', { target = food })

   local effect_loops = self._food_data.effect_loops or 3

   local quality_component = food:get_component("stonehearth:item_quality")
   local quality = (quality_component and quality_component:get_quality()) or stonehearth.constants.item_quality.NONE
   if quality > stonehearth.constants.item_quality.NORMAL then
      --for each quality tier above normal, lose a loop from our eating cycle ("scarfing it down faster")
      effect_loops = math.max(1, effect_loops - (quality-1) ) 
   end

   -- Modders can specify a different effect in the serving file (e.g. for drinks)
   local eat_effect = "eat"
   if radiant.entities.get_entity_data(entity, 'stonehearth:conversation_type') == "humanoid" then
      eat_effect = radiant.entities.get_entity_data(food, 'stonehearth:food').eating_effect or 'eat'
   end
   ai:execute('stonehearth:run_effect', {
      effect = eat_effect,
      times = effect_loops
   })

   entity:get_component('stonehearth:consumption'):consume_calories(args.food)

   local appeal_component = entity:get_component('stonehearth:appeal')
   if appeal_component then
      appeal_component:add_dining_appeal_thought()
   end
   
   ai:unprotect_argument(args.food)
   radiant.entities.destroy_entity(args.food)
   self._food_data = nil
end

function EatItem:stop(ai, entity, args)
   self._food_data = nil
end

-- food quality may differ depending on your posture (sitting can give higher satisfaction for some foods)
function EatItem:_get_food_data(food, entity)
   local food_entity_data = radiant.entities.get_entity_data(food, 'stonehearth:food')
   local food_data

   if food_entity_data then
      local posture = radiant.entities.get_posture(entity)
      food_data = food_entity_data[posture]

      if not food_data then
         food_data = food_entity_data.default
      end
   end

   return food_data
end

return EatItem
