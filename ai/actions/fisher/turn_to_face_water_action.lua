local Entity = _radiant.om.Entity
local TurnToFaceWater = class()

TurnToFaceWater.name = 'correct rotation facing the water'
TurnToFaceWater.does = 'archipelago_biome:turn_to_face_water'
TurnToFaceWater.args = {
dock = Entity
}
TurnToFaceWater.version = 2
TurnToFaceWater.priority = 1

function TurnToFaceWater:run(ai, entity, args)
	local face = radiant.entities.get_facing(args.dock)
	radiant.entities.turn_to(entity, face)
end

return TurnToFaceWater