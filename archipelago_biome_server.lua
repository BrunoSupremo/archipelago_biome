archipelago_biome = {}

function archipelago_biome:_on_required_loaded()
   local custom_world_generation_service = require('services.server.world_generation.custom_world_generation_service')
   local world_generation_service = radiant.mods.require('stonehearth.services.server.world_generation.world_generation_service')
   radiant.mixin(world_generation_service, custom_world_generation_service)

   local custom_landscaper = require('services.server.world_generation.custom_landscaper')
   local landscaper = radiant.mods.require('stonehearth.services.server.world_generation.landscaper')
   radiant.mixin(landscaper, custom_landscaper)

   local custom_height_map_renderer = require('services.server.world_generation.custom_height_map_renderer')
   local height_map_renderer = radiant.mods.require('stonehearth.services.server.world_generation.height_map_renderer')
   radiant.mixin(height_map_renderer, custom_height_map_renderer)
end

radiant.events.listen_once(radiant, 'radiant:required_loaded', archipelago_biome, archipelago_biome._on_required_loaded)

return archipelago_biome
