local HasSoldier = class()

function HasSoldier:start(ctx, info)
	local population = stonehearth.population:get_population(ctx.player_id)
	for _, citizen in population:get_citizens():each() do
		local jc = citizen:get_component('stonehearth:job')
		if jc and jc:has_role('combat') then
			return true
		end
	end

	return false
end

return HasSoldier