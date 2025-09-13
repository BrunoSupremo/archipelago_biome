local FishingDestroyBobbber = class()
local Entity = _radiant.om.Entity

FishingDestroyBobbber.name = 'destroy bobber'
FishingDestroyBobbber.does = 'archipelago_biome:destroy_bobber'
FishingDestroyBobbber.args = {}
FishingDestroyBobbber.version = 2
FishingDestroyBobbber.priority = 1

FishingDestroyBobbber.args = {
	bobber = Entity
}

function FishingDestroyBobbber:run(ai, entity, args)
	if args.bobber then
		ai:unprotect_argument(args.bobber)
		radiant.entities.destroy_entity(args.bobber)
	end
end

return FishingDestroyBobbber