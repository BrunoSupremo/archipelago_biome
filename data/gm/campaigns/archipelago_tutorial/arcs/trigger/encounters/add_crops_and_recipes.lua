local Archipelago_crops_and_recipes = class()

function Archipelago_crops_and_recipes:start(ctx, data)
	--could be done by inserting the crop alias into the initial_crops.json,
	--but then it would just target the listed kingdoms, unlisted/modded kingdoms would be left out
	local farmer_job = stonehearth.job:get_job_info(ctx.player_id, "stonehearth:jobs:farmer")
	if farmer_job then --maybe the player is using a kingdom without a farmer job?
		farmer_job:manually_unlock_crop("palm_tree")
	end

	local rayya = stonehearth.player:get_kingdom(ctx.player_id) == "rayyas_children:kingdoms:rayyas_children"

	if rayya then
		local potter_job = stonehearth.job:get_job_info(ctx.player_id, "stonehearth:jobs:potter")
		potter_job:manually_unlock_recipe("tools_weapons:fisher_bucket")
	else
		local carpenter_job = stonehearth.job:get_job_info(ctx.player_id, "stonehearth:jobs:carpenter")
		carpenter_job:manually_unlock_recipe("tools_weapons:fisher_bucket")
	end
end

return Archipelago_crops_and_recipes