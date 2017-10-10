local ArchipelagoFakeContainer = class()

function ArchipelagoFakeContainer:destroy()
	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		return
	end
	--chose the amount to spawn based on difficult
	local difficult = 2 --stonehearth:game_mode:normal
	local gamemode = stonehearth.game_creation:get_game_mode()
	if gamemode == "stonehearth:game_mode:hard" then
		difficult = 4
	end
	local cocoling
	for i=1, difficult do
		-- Create the entity and put it on the ground
		cocoling = radiant.entities.create_entity('archipelago_biome:monsters:cocoling', {owner = "forest"})
		radiant.terrain.place_entity_at_exact_location(cocoling, location)
	end
end

return ArchipelagoFakeContainer