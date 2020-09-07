local Archipelago_food_bin_is_full = class()

function Archipelago_food_bin_is_full:start(ctx, info)
	local food_bin = ctx:get("visitors.food_bin")
	if food_bin then
		return food_bin:get_component("stonehearth:storage"):is_full()
	end

	return false

end

return Archipelago_food_bin_is_full