local ArchipelagoFisherInTheWater = class()

function ArchipelagoFisherInTheWater:start(ctx, info)
	local population = stonehearth.population:get_population(ctx.player_id)
	for _, citizen in population:get_citizens():each() do
		local job = citizen:get_component("stonehearth:job"):get_job_uri()
		if job == "archipelago_biome:jobs:fisher" then
			local location = radiant.entities.get_world_grid_location(citizen)
			if location then
				local intersected_entities = radiant.terrain.get_entities_at_point(location)
				for id, entity in pairs(intersected_entities) do
					local water_component = entity:get_component('stonehearth:water')
					if water_component then
						return self:spawn_shield(location, ctx)
					end
				end
			end
		end
	end
	return false
end

function ArchipelagoFisherInTheWater:spawn_shield(location, ctx)
	local shield = radiant.entities.create_entity('archipelago_biome:armor:turtle_shield')
	location = radiant.terrain.find_placement_point(location, 1, 3, shield)
	radiant.terrain.place_entity(shield, location)

	shield = shield:get_component('stonehearth:entity_forms'):get_iconic_entity()

	local command_component = shield:add_component('stonehearth:commands')
	command_component:add_command('stonehearth:commands:loot_item')

	stonehearth.bulletin_board:post_bulletin(ctx.player_id)
	:set_data({
		zoom_to_entity = shield,
		title = "i18n(archipelago_biome:data.gm.campaigns.archipelago_campaign.trigger.shield_spawned.found)"
		})

	return true
end

return ArchipelagoFisherInTheWater