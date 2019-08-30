archipelago_biome = {}
print("Archipelago Biome Mod version 19.8.29")

--[[
add jellyfish
rework pirate hat

Bugs:

]]

function archipelago_biome:_on_biome_set(e)
	if e.biome_uri ~= "archipelago_biome:biome:archipelago" then
		return
	end

	local custom_landscaper = require('services.server.world_generation.custom_landscaper')
	local landscaper = radiant.mods.require('stonehearth.services.server.world_generation.landscaper')
	radiant.mixin(landscaper, custom_landscaper)

	local custom_height_map_renderer = require('services.server.world_generation.custom_height_map_renderer')
	local height_map_renderer = radiant.mods.require('stonehearth.services.server.world_generation.height_map_renderer')
	radiant.mixin(height_map_renderer, custom_height_map_renderer)

	local custom_micro_map_generator = require('services.server.world_generation.custom_micro_map_generator')
	local micro_map_generator = radiant.mods.require('stonehearth.services.server.world_generation.micro_map_generator')
	radiant.mixin(micro_map_generator, custom_micro_map_generator)
end

radiant.events.listen_once(radiant, 'stonehearth:biome_set', archipelago_biome, archipelago_biome._on_biome_set)

return archipelago_biome