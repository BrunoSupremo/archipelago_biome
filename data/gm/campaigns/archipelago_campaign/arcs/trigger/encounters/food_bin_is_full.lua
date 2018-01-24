local Archipelago_food_bin_is_full = class()

function Archipelago_food_bin_is_full:start(ctx, info)
	-- local parent_node = ctx:get_data().parent_node
	-- if parent_node then
		-- local food_bin = parent_node:get_ctx():get("visitors.food_bin")
		local food_bin = ctx:get("visitors.food_bin")
		if food_bin then
			return food_bin:get_component("stonehearth:storage"):is_full()
		end
	-- end

	return false

	-- local inventory = stonehearth.inventory:get_inventory(ctx.player_id)
	-- local matching = inventory and inventory:get_items_of_type("archipelago_biome:monsters:fake_container")
	-- if matching and matching.items then
	-- 	for uri, entity in pairs(matching.items) do
	-- 		if radiant.entities.exists_in_world(entity) then
	-- 			return true
	-- 		end
	-- 	end
	-- end
	-- return false
end

return Archipelago_food_bin_is_full