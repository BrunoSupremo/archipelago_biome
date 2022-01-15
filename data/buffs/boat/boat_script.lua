local BoatAddBuffOnExpire = class()
local Point3 = _radiant.csg.Point3

function BoatAddBuffOnExpire:on_buff_removed(entity, buff)
	if buff and buff:is_duration_expired() then
		local location = radiant.entities.get_world_grid_location(entity)
		if not location then
			return
		end
		if radiant.terrain.is_blocked(location - Point3.unit_y) then
			local entity_container = entity:get_component('entity_container')
			if entity_container then
				for child_id, child in entity_container:each_attached_item() do
					if child:get_uri() == "archipelago_biome:gizmos:boat" then
						entity_container:remove_child(child_id)
						radiant.entities.destroy_entity(child)
					end
				end
			end
			local mob = entity:add_component('mob')
			mob:set_model_origin(Point3.zero)
		else
			radiant.entities.add_buff(entity, "archipelago_biome:buffs:boat")
		end
	end
end

return BoatAddBuffOnExpire