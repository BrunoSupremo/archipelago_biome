archipelago_biome = {}
local log = radiant.log.create_logger('version')
log:error("Archipelago Biome Mod last updated at Stonehearth 1.0.0.907")

function archipelago_biome:_on_required_loaded()
	local custom_biome = require('services.server.world_generation.custom_biome')
	local biome = radiant.mods.require('stonehearth.services.server.world_generation.biome')
	radiant.mixin(biome, custom_biome)
end

function archipelago_biome:_on_services_init()

end

function archipelago_biome:_on_biome_set(e)
	if e.biome_uri ~= "archipelago_biome:biome:archipelago" then
		return
	end
	local custom_world_generation_service = require('services.server.world_generation.custom_world_generation_service')
	local world_generation_service = radiant.mods.require('stonehearth.services.server.world_generation.world_generation_service')
	radiant.mixin(world_generation_service, custom_world_generation_service)

	local custom_landscaper = require('services.server.world_generation.custom_landscaper')
	local landscaper = radiant.mods.require('stonehearth.services.server.world_generation.landscaper')
	radiant.mixin(landscaper, custom_landscaper)

	local custom_height_map_renderer = require('services.server.world_generation.custom_height_map_renderer')
	local height_map_renderer = radiant.mods.require('stonehearth.services.server.world_generation.height_map_renderer')
	radiant.mixin(height_map_renderer, custom_height_map_renderer)

	local custom_micro_map_generator = require('services.server.world_generation.custom_micro_map_generator')
	local micro_map_generator = radiant.mods.require('stonehearth.services.server.world_generation.micro_map_generator')
	radiant.mixin(micro_map_generator, custom_micro_map_generator)

	local custom_habitat_manager = require('services.server.world_generation.custom_habitat_manager')
	local habitat_manager = radiant.mods.require('stonehearth.services.server.world_generation.habitat_manager')
	radiant.mixin(habitat_manager, custom_habitat_manager)
end

radiant.events.listen_once(radiant, 'radiant:services:init', archipelago_biome, archipelago_biome._on_services_init)
radiant.events.listen_once(radiant, 'radiant:required_loaded', archipelago_biome, archipelago_biome._on_required_loaded)
radiant.events.listen_once(radiant, 'stonehearth:biome_set', archipelago_biome, archipelago_biome._on_biome_set)
radiant.util.set_global_config('mods.directory.cfm.enabled', false)
radiant.util.set_global_config('mods.steam_workshop.cfm.enabled', false)
return archipelago_biome