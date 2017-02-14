local Archipelago_crops_recipes_adder = class()

function Archipelago_crops_recipes_adder:start(ctx, data)
   local farmer_job = stonehearth.job:get_job_info(ctx.player_id, "stonehearth:jobs:farmer")
   farmer_job:manually_unlock_crop("palm_tree")

   local cook_job = stonehearth.job:get_job_info(ctx.player_id, "stonehearth:jobs:cook")
   cook_job:manually_unlock_recipe("decoration:fruit_container")
   local potter_job = stonehearth.job:get_job_info(ctx.player_id, "stonehearth:jobs:potter")
   potter_job:manually_unlock_recipe("furniture:sand_castle")
end

return Archipelago_crops_recipes_adder