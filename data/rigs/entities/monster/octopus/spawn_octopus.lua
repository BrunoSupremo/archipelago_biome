	local location = radiant.entities.get_world_grid_location(e)
	local cocoling = radiant.entities.create_entity('archipelago_biome:monsters:octopus', {owner = "forest"})
	radiant.terrain.place_entity_at_exact_location(cocoling, location)