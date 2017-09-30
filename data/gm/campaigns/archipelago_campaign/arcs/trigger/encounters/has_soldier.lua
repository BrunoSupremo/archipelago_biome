local HasSoldier = class()

function HasSoldier:start(ctx, info)
	local population = stonehearth.population:get_population(ctx.player_id)
	local party = population:get_party_by_name('party_1')
	local party_component = party:get_component('stonehearth:party')
	
	return party_component:get_party_size()
end

return HasSoldier