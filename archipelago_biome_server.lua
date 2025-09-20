archipelago_biome = {}
print("Archipelago Biome Mod version 25.9.20")

--[[

Floating Markets: Imagine bustling markets on large wooden rafts or floating platforms. Traders from different islands gather to exchange goods, and players can participate by setting up their own floating market stalls. The market could feature unique items, rare resources, and exotic pets.
trader with diver gear

check ace extending bridge renderer

underwater volcano

boat as decor

waterzilla

zone renderer for fish docks and crab trap

ostrich rig for aquatic/ness monsters

fix/redo boat mechanics

fisher village, landmark, ~3x3 chunks

spawn whale, poyo rig. or as a fancy and decorated landmark

rework pirate hat

Bugs:
(vanilla) chairs stocked on fish only container because it has the "all" option set --too hard to fix
varanus boat riding animation

things to look up for inspiration:
	pirates of the caribean
	one piece
	atlantis
	moana
	tropico

----
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

		local custom_follow_path_action = require('ai.actions.custom_follow_path_action')
		local follow_path_action = radiant.mods.require('stonehearth.ai.actions.follow_path_action')
		radiant.mixin(follow_path_action, custom_follow_path_action)
	end

	local custom_renewable_resource_node = require('components.renewable_resource_node.custom_renewable_resource_node_component')
	local renewable_resource_node = radiant.mods.require('stonehearth.components.renewable_resource_node.renewable_resource_node_component')
	radiant.mixin(renewable_resource_node, custom_renewable_resource_node)
end

radiant.events.listen_once(radiant, 'radiant:required_loaded', archipelago_biome, archipelago_biome._on_required_loaded)
radiant.events.listen_once(radiant, 'stonehearth:biome_set', archipelago_biome, archipelago_biome._on_biome_set)

return archipelago_biome