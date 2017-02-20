local EruptComponent = class()
local rng = _radiant.math.get_default_rng()

function EruptComponent:initialize()
   self._sv.erupt_timer = nil
end

function EruptComponent:activate()
   self._erupt_data = radiant.entities.get_entity_data(self._entity, 'archipelago_biome:erupt_data')
   self:_start()
end

function EruptComponent:_start()
   if not self._sv.erupt_timer then
      self:_start_erupt_timer(self._erupt_data.erupt_time)
   else
      if self._sv.erupt_timer then
         self._sv.erupt_timer:bind(function()
            self:erupt()
            end)
      end
   end
end

function EruptComponent:destroy()
   if self._added_to_world_trace then
      self._added_to_world_trace:destroy()
      self._added_to_world_trace = nil
   end

   self:_stop_erupt_timer()
end

function EruptComponent:erupt()
   self:_stop_erupt_timer()

   local location = radiant.entities.get_world_grid_location(self._entity)
   if not location then
      --destroy???-------------------------
      return
   end
   
   --Create the entity and put it on the ground
   local hot_rock = radiant.entities.create_entity("archipelago_biome:resources:hot_rock", {})

   location.x = location.x + rng:get_int(-10,10)
   location.z = location.z + rng:get_int(-10,10)
   
   radiant.terrain.place_entity_at_exact_location(hot_rock, location)
   
   local erupt_effect = self._erupt_data.erupt_effect
   if erupt_effect then
      radiant.effects.run_effect(hot_rock, erupt_effect)
   end

   radiant.events.trigger(self._entity, 'archipelago_biome:on_erupted', {entity = self._entity, hot_rock = hot_rock})
   
   self:_start_erupt_timer(self._erupt_data.erupt_time)
end

function EruptComponent:_start_erupt_timer(duration)
   self:_stop_erupt_timer()

   self._sv.erupt_timer = stonehearth.calendar:set_persistent_timer("EruptComponent renew", duration,
      function ()
         self:erupt()
      end
      )

   self.__saved_variables:mark_changed()
end

function EruptComponent:_stop_erupt_timer()
   if self._sv.erupt_timer then
      self._sv.erupt_timer:destroy()
      self._sv.erupt_timer = nil
   end

   self.__saved_variables:mark_changed()
end

return EruptComponent