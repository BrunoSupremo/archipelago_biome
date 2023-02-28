archipelago_biome = {}
print("Archipelago Biome Mod version 23.2.27")

--[[

ostrich rig for aquatic monsters

aquatic citizen immigrant, at level 6 fisher + tier 3 town

fix boats

fisher village, landmark, ~3x3 chunks

spawn whale, poyo rig. or as a fancy and decorated landmark

wave effect for storm weather

rework pirate hat

Bugs:
(vanilla) chairs stocked on fish only container because it has the "all" option set --too hard to fix

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

function archipelago_biome:_on_required_loaded()
	local mod_list = radiant.resources.get_mod_list()
	archipelago_biome.ace_is_here = false
	for i, mod in ipairs(mod_list) do
		if mod == "stonehearth_ace" then
			archipelago_biome.ace_is_here = true
			break
		end
	end
	if not archipelago_biome.ace_is_here then
		local custom_seasons_service = require('services.server.seasons.custom_seasons_service')
		local seasons_service = radiant.mods.require('stonehearth.services.server.seasons.seasons_service')
		radiant.mixin(seasons_service, custom_seasons_service)
	end
end

radiant.events.listen_once(radiant, 'radiant:required_loaded', archipelago_biome, archipelago_biome._on_required_loaded)
radiant.events.listen_once(radiant, 'stonehearth:biome_set', archipelago_biome, archipelago_biome._on_biome_set)

return archipelago_biome