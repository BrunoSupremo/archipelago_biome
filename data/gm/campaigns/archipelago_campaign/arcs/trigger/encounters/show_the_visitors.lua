local ArchipelagoShowTheVisitors = class()
local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3
local Region2 = _radiant.csg.Region2
local Rect2 = _radiant.csg.Rect2
local game_master_lib = require 'stonehearth.lib.game_master.game_master_lib'

function ArchipelagoShowTheVisitors:initialize()
	self._sv.searcher = nil
end

function ArchipelagoShowTheVisitors:start(ctx, info)
	self._sv.searcher = radiant.create_controller('archipelago_biome:game_master:util:choose_water_location_outside_town',
		16, 100,
		function(op, location)
			return self:_find_location_callback(op, location, ctx)
			end,
			nil,
			ctx.player_id)
end

function ArchipelagoShowTheVisitors:_find_location_callback(op, location, ctx)
	if op == 'check_location' then
		return true
	--dummy comment just to fix the elseif auto indent problem
	elseif op == 'set_location' then
		self:create_visitors(ctx, location)
	--dummy comment just to fix the elseif auto indent problem
	elseif op == 'abort' then
		local town = stonehearth.town:get_town(ctx.player_id)
		local location = town:get_landing_location()
		location.y = 39
		location = radiant.terrain.find_placement_point(location, 64, 320, false, 12)
		if not location then
			return
		end
		self:create_visitors(ctx, location)
	else
		radiant.error('unknown op "%s" in choose_location_outside_town callback', op)
	end
end

function ArchipelagoShowTheVisitors:create_visitors(ctx, location)
	local player_id = ctx.player_id
	local raft = radiant.entities.create_entity("archipelago_biome:decoration:raft", {owner = player_id})
	radiant.terrain.place_entity(raft, location, { force_iconic = false })

	local pop = stonehearth.population:get_population(player_id)
	for i=1,3 do
		local visitor
		if i == 3 then
			visitor = radiant.entities.create_entity("archipelago_biome:anya", {owner = player_id})
			radiant.entities.set_custom_name(visitor, "i18n(archipelago_biome:entities.humans.anya.display_name)")
		else
			visitor = radiant.entities.create_entity("stonehearth:female_"..i, {owner = player_id})
			pop:set_citizen_name(visitor, 'female')
		end
		visitor:add_component('stonehearth:customization'):generate_custom_appearance()
		visitor:add_component('stonehearth:job'):promote_to("stonehearth:jobs:worker")
		visitor:add_component('stonehearth:equipment'):equip_item("archipelago_biome:outfit:visitor")
		local new_location = radiant.terrain.find_placement_point(location, 2, 5, visitor)
		radiant.terrain.place_entity(visitor, new_location)
		game_master_lib.register_entities(ctx, 'visitors', { ["female_"..i] = visitor })
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

	stonehearth.bulletin_board:post_bulletin(ctx.player_id)
	:set_data({
		zoom_to_entity = ctx.visitors.female_3,
		title = "i18n(archipelago_biome:data.gm.campaigns.archipelago_campaign.trigger.show_the_visitors.show)"
		})
end

function ArchipelagoShowTheVisitors:destroy()
	if self._sv.searcher then
		self._sv.searcher:destroy()
		self._sv.searcher = nil
	end
end

return ArchipelagoShowTheVisitors