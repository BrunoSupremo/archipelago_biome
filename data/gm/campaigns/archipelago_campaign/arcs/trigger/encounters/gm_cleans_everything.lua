local Archipelago_gm_cleans_everything = class()

function Archipelago_gm_cleans_everything:start(ctx, info)
	local food_bin = ctx:get("visitors.food_bin")
	if food_bin then
		radiant.entities.destroy_entity(food_bin)
	end
	local parent_node = ctx:get_data().parent_node
	while not parent_node:get_ctx():get("visitors.female_1") do
		if parent_node:get_ctx():get_data().parent_node then
			parent_node = parent_node:get_ctx():get_data().parent_node
		else
			return
		end
	end

	local female = parent_node:get_ctx():get("visitors.female_1")
	radiant.entities.destroy_entity(female)
	female = parent_node:get_ctx():get("visitors.female_2")
	radiant.entities.destroy_entity(female)
	female = parent_node:get_ctx():get("visitors.female_3")
	radiant.entities.destroy_entity(female)
end

return Archipelago_gm_cleans_everything