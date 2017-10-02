local Archipelago_spawn_mysterious_crate = class()

function Archipelago_spawn_mysterious_crate:initialize()
   self._sv.searcher = nil
end

function Archipelago_spawn_mysterious_crate:start(ctx, data)
	if data and data.spawn_outside then
		self._sv.searcher = radiant.create_controller('stonehearth:game_master:util:choose_location_outside_town',
			ctx.player_id, 16, 190,
			function(op, location)
				return self:_find_location_callback(op, location, ctx)
			end)
		return
	end
	local town = stonehearth.town:get_town(ctx.player_id)
	local location = town:get_landing_location()
	location = radiant.terrain.find_placement_point(location, 2, 7)
	if not location then
		return
	end
	self:_spawn(location, ctx)
end

function Archipelago_spawn_mysterious_crate:_spawn(location, ctx)
	local fake_container = radiant.entities.create_entity('archipelago_biome:monsters:fake_container', {owner = "animals"})
	local inventory = stonehearth.inventory:get_inventory("animals")
	inventory:add_item(fake_container)
	radiant.terrain.place_entity(fake_container, location)

	stonehearth.bulletin_board:post_bulletin(ctx.player_id)
	:set_data({
		zoom_to_entity = fake_container,
		title = "i18n(archipelago_biome:data.gm.campaigns.archipelago.arcs.trigger.miranda_notice_a_lost_crate.this_crate)"
	})
end

function Archipelago_spawn_mysterious_crate:_find_location_callback(op, location, ctx)
	if op == 'check_location' then
		return true
	elseif op == 'set_location' then
		self:_spawn(location, ctx)
	elseif op == 'abort' then
		local town = stonehearth.town:get_town(ctx.player_id)
		local location = town:get_landing_location()
		location = radiant.terrain.find_placement_point(location, 2, 7)
		if not location then
			return
		end
		self:_spawn(location, ctx)
	else
		radiant.error('unknown op "%s" in choose_location_outside_town callback', op)
	end
end

function Archipelago_spawn_mysterious_crate:destroy()
   if self._sv.searcher then
      self._sv.searcher:destroy()
      self._sv.searcher = nil
   end
end

return Archipelago_spawn_mysterious_crate