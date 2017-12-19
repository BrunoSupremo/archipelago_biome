local ArchipelagoShowTheVisitors = class()
local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3
local Region2 = _radiant.csg.Region2
local Rect2 = _radiant.csg.Rect2
local game_master_lib = require 'stonehearth.lib.game_master.game_master_lib'

function ArchipelagoShowTheVisitors:create_visitors(ctx, wave)
	local player_id = ctx.player_id
	local raft = radiant.entities.create_entity("archipelago_biome:decoration:raft", {owner = player_id})
	local location = radiant.entities.get_world_grid_location(wave)
	radiant.terrain.place_entity(raft, location, { force_iconic = false })
	game_master_lib.register_entities(ctx, 'visitors', { raft = raft })

	for i=1,3 do
		local visitor = radiant.entities.create_entity("stonehearth:female_"..i, {owner = player_id})
		visitor:add_component('stonehearth:customization'):generate_custom_appearance()
		visitor:add_component('stonehearth:job'):promote_to("stonehearth:jobs:worker")
		visitor:add_component('stonehearth:equipment'):equip_item("stonehearth/jobs/mason/mason_outfit/mason_outfit.json")
		local new_location = radiant.terrain.find_placement_point(location+Point3(0,1,0), 1, 3, visitor)
		radiant.terrain.place_entity(visitor, new_location)
		game_master_lib.register_entities(ctx, 'visitors', { [i] = visitor })
	end
	
	-- add to the visible region for that player
	local visible_rgn = Region2()
	local rcs = raft:get_component('region_collision_shape')
	local world_rgn = radiant.entities.local_to_world(rcs:get_region():get(), raft)
	for cube in world_rgn:each_cube() do
		local min = Point2(cube.min.x, cube.min.z) - Point2(16, 16)
		local max = Point2(cube.max.x, cube.max.z) + Point2(16, 16)
		visible_rgn:add_cube(Rect2(min, max))
	end
	stonehearth.terrain:get_explored_region(player_id)
	:modify(function(cursor)
		cursor:add_region(visible_rgn)
		end)

	return raft
end

function ArchipelagoShowTheVisitors:start(ctx, info)
	local wave
	local waves = {}
	local territory = stonehearth.terrain:get_territory(ctx.player_id)
	local town_center = territory:get_centroid()
	local ec = radiant._root_entity:get_component('entity_container')
	if ec then
		for id, child in ec:each_child() do
			if child:get_uri() == "archipelago_biome:beach:wave" then
				local position = radiant.entities.get_world_grid_location(child)
				local distance = Point2(position.x, position.z):distance_to(town_center)
				waves[id] = {child = child, distance = distance}
			end
		end
	end
	table.sort(waves,
		function (a, b)
			return a.distance < b.distance
		end
		)
	for id, entity in pairs(waves) do
		if entity.distance > 100 then
			wave = entity.child
			break
		end
	end

	local raft = self:create_visitors(ctx, wave)

	stonehearth.bulletin_board:post_bulletin(ctx.player_id)
	:set_data({
		zoom_to_entity = raft,
		title = "i18n(archipelago_biome:data.gm.campaigns.archipelago_campaign.trigger.shield_spawned.found)"
		})
end

return ArchipelagoShowTheVisitors