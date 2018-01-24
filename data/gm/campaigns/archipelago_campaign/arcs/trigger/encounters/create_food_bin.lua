local Archipelago_create_food_bin = class()
local game_master_lib = require 'stonehearth.lib.game_master.game_master_lib'

function Archipelago_create_food_bin:start(ctx, data)
	local town = stonehearth.town:get_town(ctx.player_id)
	local location = town:get_landing_location()
	if not location then
		return
	end
	self:_spawn(location, ctx)
end

function Archipelago_create_food_bin:_spawn(location, ctx)
	local food_bin = radiant.entities.create_entity('archipelago_biome:containers:input_bin:food_bin', {owner = ctx.player_id})
	local inventory = stonehearth.inventory:get_inventory(ctx.player_id)
	inventory:add_item(food_bin)
	location = radiant.terrain.find_placement_point(location, 1, 10, food_bin)
	radiant.terrain.place_entity(food_bin, location, { force_iconic = false })
	radiant.entities.set_custom_name(food_bin, "i18n(archipelago_biome:entities.containers.input_food_bin.display_name)")
	radiant.entities.set_description(food_bin, "i18n(archipelago_biome:entities.containers.input_food_bin.description)")
	game_master_lib.register_entities(ctx, 'visitors', { food_bin = food_bin })
end

return Archipelago_create_food_bin