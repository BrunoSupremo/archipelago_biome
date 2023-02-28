local Archipelago_Unlock_Stuff = class()

function Archipelago_Unlock_Stuff:start(ctx, data)
	local biome = stonehearth.world_generation:get_biome_alias()

	local farmer_job = stonehearth.job:get_job_info(ctx.player_id, "stonehearth:jobs:farmer")
	if farmer_job and biome == "archipelago_biome:biome:archipelago" then
		farmer_job:manually_unlock_crop("palm_tree")
	end
	local fisher_job = stonehearth.job:get_job_info(ctx.player_id, "archipelago_biome:jobs:fisher")
	if fisher_job and biome == "stonehearth:biome:arctic" then
		fisher_job:manually_unlock_recipe("fishing:ice_dock")
	end
end

return Archipelago_Unlock_Stuff