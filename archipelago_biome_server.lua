archipelago_biome = {
version = 24
}
local log = radiant.log.create_logger('version')
log:error("Archipelago Biome mod for alpha %d", archipelago_biome.version)

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

	local custom_micro_map_generator = require('services.server.world_generation.custom_micro_map_generator')
	local micro_map_generator = radiant.mods.require('stonehearth.services.server.world_generation.micro_map_generator')
	radiant.mixin(micro_map_generator, custom_micro_map_generator)

	local custom_population_faction = require('services.server.population.custom_population_faction')
	local population_faction = radiant.mods.require('stonehearth.services.server.population.population_faction')
	radiant.mixin(population_faction, custom_population_faction)

	local custom_resource_call_handler = require('call_handlers.custom_resource_call_handler')
	local resource_call_handler = radiant.mods.require('stonehearth.call_handlers.resource_call_handler')
	radiant.mixin(resource_call_handler, custom_resource_call_handler)
end

radiant.events.listen_once(radiant, 'radiant:required_loaded', archipelago_biome, archipelago_biome._on_required_loaded)
radiant.events.listen_once(stonehearth.game_creation, 'stonehearth:world_generation_complete', function()
	stonehearth.calendar:set_timer('stonehearth:world_generation_complete + 1m', "1m", function()
		local biome_name = stonehearth.world_generation:get_biome_alias()
		if biome_name == "archipelago_biome:biome:archipelago" then
			local alpha = _radiant.sim.get_product_minor_version()
			if alpha > archipelago_biome.version then
				stonehearth.bulletin_board:post_bulletin("player_1")
				:set_ui_view('StonehearthGenericBulletinDialog')
				:set_sticky(true)
				:set_data({
					title = "i18n(archipelago_biome:data.version_check.title)",
					message = "i18n(archipelago_biome:data.version_check.message)",
					ok_callback = 'There_is_no_one_who_loves_pain_itself___who_seeks_after_it_and_wants_to_have_it___simply_because_it_is_pain'
					})
				:add_i18n_data('current_mod_version', archipelago_biome.version)
				:add_i18n_data('current_alpha', alpha)
			end
		end
		end)
	end)

return archipelago_biome