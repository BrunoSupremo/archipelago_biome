archipelago_biome = {}

radiant.events.listen(radiant, 'radiant:client:terrain_ready', function()
	_radiant.call('stonehearth:get_service', 'world_generation')
	:done(function(r)
		local wgs = r.result
		if wgs:get_data().biome_alias == "archipelago_biome:biome:archipelago" then
			radiant.create_controller("archipelago_biome:weather_renderers:water_glint")
		end
	end)
end)

return archipelago_biome