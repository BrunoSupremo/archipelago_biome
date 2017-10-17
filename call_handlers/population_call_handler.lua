local ArchipelagoPopulationCallHandler = class()

function ArchipelagoPopulationCallHandler:generate_town_name(session, response)
   local population = stonehearth.population:get_population(session.player_id)
   return population:generate_town_name_for_archipelago_biome()
end

return ArchipelagoPopulationCallHandler