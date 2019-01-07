local ArchipelagoTrojan = class()
local rng = _radiant.math.get_default_rng()

function ArchipelagoTrojan:activate()
	if stonehearth.game_creation:get_game_mode() == "stonehearth:game_mode:peaceful" then
		return
	end
	self._on_kill_listener = radiant.events.listen(self._entity, 'stonehearth:kill_event', function(args)
		self:kill()
		self._on_kill_listener = nil
		end)
end

function ArchipelagoTrojan:destroy()
	if self._on_kill_listener then
		self._on_kill_listener:destroy()
		self._on_kill_listener = nil
	end
end

function ArchipelagoTrojan:kill()
	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		return
	end

	local json = radiant.entities.get_json(self)

	local game_mode = stonehearth.game_creation:get_game_mode()
	if game_mode == "stonehearth:game_mode:hard" and json.in_game_mode_hard then
		for key,value in pairs(json.in_game_mode_hard) do
			if json[key] then
				json[key] = value
			end
		end
	end
	if json.no_trojan_percent_chance then
		if rng:get_real(0,100) <= json.no_trojan_percent_chance then
			return
		end
	end


	local uri = json.uri
	if radiant.util.is_table(uri) then
		uri = uri[rng:get_int(1, #uri)]
	end
	for i=1, rng:get_int(json.min,json.max) do
		local entity = radiant.entities.create_entity(uri, {owner = json.player_id})
		if json.equipment then
			entity:get_component("stonehearth:equipment"):equip_item(json.equipment)
		end
		if json.scale then
			entity:get_component("render_info"):set_scale(json.scale)
		end
		if json.loot_drops then
			if json.loot_drops == "remove" then
				entity:remove_component("stonehearth:loot_drops")
			else
				entity:get_component("stonehearth:loot_drops"):set_loot_table(json.loot_drops)
			end
		end
		radiant.terrain.place_entity_at_exact_location(entity, location)
	end
end

return ArchipelagoTrojan