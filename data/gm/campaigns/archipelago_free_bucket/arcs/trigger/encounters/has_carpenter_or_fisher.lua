local Archipelago_has_carpenter_or_fisher = class()

function Archipelago_has_carpenter_or_fisher:start(ctx, info)
	local carpenter_job = stonehearth.job:get_job_info(ctx.player_id, "stonehearth:jobs:carpenter")
	if carpenter_job and carpenter_job:get_highest_level()>0 then
		return true
	end
	local fisher_job = stonehearth.job:get_job_info(ctx.player_id, "archipelago_biome:jobs:fisher")
	if fisher_job and fisher_job:get_highest_level()>0 then
		return true
	end
	return false
end

return Archipelago_has_carpenter_or_fisher