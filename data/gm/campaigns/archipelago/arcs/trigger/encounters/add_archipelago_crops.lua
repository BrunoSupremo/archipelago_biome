local Archipelago_crops_adder = class()

function Archipelago_crops_adder:start(ctx, data)
	--could be done by inserting the crop alias into the initial_crops.json,
	--but then it would just target the listed kingdoms, unlisted/modded kingdoms would be left out
	local farmer_job = stonehearth.job:get_job_info(ctx.player_id, "stonehearth:jobs:farmer")
	if farmer_job then --maybe the player is using a kingdom without a farmer job?
		farmer_job:manually_unlock_crop("palm_tree")
	end
end

return Archipelago_crops_adder