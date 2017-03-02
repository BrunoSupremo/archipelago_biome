local ArchipelagoCrateExists = class()

function ArchipelagoCrateExists:start(ctx, info)
	local inventory = stonehearth.inventory:get_inventory("animals")
	local matching = inventory and inventory:get_items_of_type("archipelago_biome:monsters:fake_container")
	if matching and matching.items then
		for uri, entity in pairs(matching.items) do
			if radiant.entities.exists_in_world(entity) then
				return true
			end
		end
	end
	return false
end

return ArchipelagoCrateExists