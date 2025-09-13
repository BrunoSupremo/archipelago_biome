local ArchipelagoTrojan = class()
local rng = _radiant.math.get_default_rng()

function ArchipelagoTrojan:post_activate()
	local sensor_list = self._entity:get_component('sensor_list')
	local sensor = sensor_list and sensor_list:get_sensor("trojan_sensor")
	if sensor then
		self._sensor_trace = sensor:trace_contents('trojan')
		:on_added(function (id, entity)
			self:_on_added_to_sensor(id, entity)
		end)
		:push_object_state()
	end
end

function ArchipelagoTrojan:_on_added_to_sensor(id, entity)
	if radiant.entities.is_owned_by_non_npc(entity) then
		radiant.entities.kill_entity(self._entity)
		return
	end
end

function ArchipelagoTrojan:destroy()
	--for some reason, it has to be on destroy, not kill
	--if run on kill event, entities will spawn frozen, no ai
	if self._sensor_trace then
		self._sensor_trace:destroy()
		self._sensor_trace = nil
	end

	local game_mode = stonehearth.game_creation:get_game_mode()
	if game_mode == "stonehearth:game_mode:peaceful" then
		return
	end

	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		return
	end

	local json = radiant.entities.get_json(self)

	if json.game_mode_customized and json.game_mode_customized[game_mode] then
		for key,value in pairs(json.game_mode_customized[game_mode]) do
			json[key] = value
		end
	end
	if json.trojan_percent_chance then
		if rng:get_real(0,100) >= json.trojan_percent_chance then
			return
		end
	end

	local game_mode_buff = nil
	local monster_tuning_overrides = stonehearth.game_creation:get_game_mode_json().monster_tuning_overrides
	if monster_tuning_overrides and monster_tuning_overrides.default.add_buffs then
		for _, buff_uri in pairs(monster_tuning_overrides.default.add_buffs) do
			if buff_uri and buff_uri ~= "" then
				game_mode_buff = buff_uri
			end
		end
	end

	for i=1, rng:get_int(json.min,json.max) do
		local uri = json.uri
		if radiant.util.is_table(uri) then
			uri = uri[rng:get_int(1, #uri)]
		end
		local entity = radiant.entities.create_entity(uri, {owner = json.player_id})

		if json.custom_name then
			radiant.entities.set_custom_name(entity, json.custom_name)
		end
		if json.attributes then
			local attrib_component = entity:add_component('stonehearth:attributes')
			for name, value in pairs(json.attributes) do
				attrib_component:set_attribute(name, value)
			end
		end
		if json.job then
			entity:add_component('stonehearth:job'):promote_to(json.job)
		end
		if json.equipment then
			local equipment_component = entity:add_component("stonehearth:equipment")
			for equipment_category, equipment_array in pairs(json.equipment) do
				local equip = equipment_array[rng:get_int(1, #equipment_array)]
				equipment_component:equip_item(equip)
			end
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
		if game_mode_buff then
			radiant.entities.add_buff(entity, game_mode_buff)
		end
		local random_location = radiant.terrain.find_placement_point(location, 0, 2, entity, nil, true)
		radiant.terrain.place_entity_at_exact_location(entity, random_location)
	end
end

return ArchipelagoTrojan