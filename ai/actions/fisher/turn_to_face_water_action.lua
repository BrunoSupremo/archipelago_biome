local Entity = _radiant.om.Entity
local TurnToFaceWater = class()
local rng = _radiant.math.get_default_rng()

TurnToFaceWater.name = 'correct rotation facing the water'
TurnToFaceWater.does = 'archipelago_biome:turn_to_face_water'
TurnToFaceWater.args = {
	dock = Entity
}
TurnToFaceWater.version = 2
TurnToFaceWater.priority = 1

function TurnToFaceWater:run(ai, entity, args)
	if radiant.entities.get_posture(entity) == "stonehearth:in_boat" then
		radiant.entities.turn_to(entity, rng:get_int(0,360))
	else
		local face = 0
		local fisher_field_component = args.dock:get_component("archipelago_biome:fisher_field")
		if fisher_field_component then
			local water_location = fisher_field_component:get_water_direction(radiant.entities.get_world_grid_location(entity))
			if water_location then
				entity:get_component('mob'):turn_to_face_point(water_location)
			end
			face = radiant.entities.get_facing(entity)
		else
			face = radiant.entities.get_facing(args.dock)
		end
		radiant.entities.turn_to(entity, face+rng:get_int(-35,35))
	end
end

return TurnToFaceWater