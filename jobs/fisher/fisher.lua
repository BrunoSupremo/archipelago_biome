local CraftingJob = require 'stonehearth.jobs.crafting_job'
local BaseJob = require 'stonehearth.jobs.base_job'
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local rng = _radiant.math.get_default_rng()

--lure types hardcoded for now, i was just lazy
--if anyone needs this exposed in json for further modding, just tell me
local lure_switch = {
	default = {
		remove_command = "archipelago_biome:commands:fishing_default",
		add_command = "archipelago_biome:commands:fishing_big_lure",
		switch_to_new_lure = "big_lure"
	},
	big_lure = {
		remove_command = "archipelago_biome:commands:fishing_big_lure",
		add_command = "archipelago_biome:commands:fishing_plant_lure",
		switch_to_new_lure = "plant_lure"
	},
	plant_lure = {
		remove_command = "archipelago_biome:commands:fishing_plant_lure",
		add_command = "archipelago_biome:commands:fishing_trinket_lure",
		switch_to_new_lure = "trinket_lure"
	},
	trinket_lure = {
		remove_command = "archipelago_biome:commands:fishing_trinket_lure",
		add_command = "archipelago_biome:commands:fishing_default",
		switch_to_new_lure = "default"
	}
}

local FisherClass = class()
radiant.mixin(FisherClass, CraftingJob)

function FisherClass:initialize()
	CraftingJob.initialize(self)
	self._sv.fished = {} --deprecated
	self._sv.current_loot = nil --deprecated too, no need to save it
	self._sv.current_fish = nil --deprecated
	self._sv.current_lure = "default"
end

function FisherClass:restore()
	if self._sv.is_current_class then
		self:_register_with_town()
	end
	if self:is_max_level() and not self:has_perk("crafter_recipe_unlock_6") then
		self:fishing_options()
	end

	--removing deprecated stuff
	if self._sv.current_loot then
		radiant.entities.destroy_entity(self._sv.current_loot.entity)
		self._sv.current_loot = nil
	end
	if self._sv.current_fish then
		radiant.entities.destroy_entity(self._sv.current_fish)
		self._sv.current_fish = nil
	end
	if next(self._sv.fished) then
		self._sv.fished = nil
	end
end

function FisherClass:activate()
	BaseJob.activate(self)
	self.current_loot = {}
	self.biome_alias = stonehearth.world_generation:get_biome_alias()
	self.player_id = radiant.entities.get_player_id(self._sv._entity)
	self.kingdom_alias = stonehearth.player:get_kingdom(self.player_id)
	if self._sv.is_current_class then
		self:_register_with_town()
	end
	self.fishing_data = radiant.resources.load_json("archipelago_biome:data:fishing", true, false)
	radiant.on_game_loop_once('prepare_next_fish_loot delay', function()
		self:prepare_next_fish_loot()
	end)
end

function FisherClass:promote(json_path, options)
	CraftingJob.promote(self, json_path, options)
	self:_register_with_town()
	self:prepare_next_fish_loot()
end

function FisherClass:_register_with_town()
	local player_id = radiant.entities.get_player_id(self._sv._entity)
	local town = stonehearth.town:get_town(player_id)
	if town then
		town:add_placement_slot_entity(self._sv._entity, {fish_trap = 2})
		if not town._sv.fished then
			town._sv.fished = {}
		end
		self.town_fished = town._sv.fished
	end
	self.__saved_variables:mark_changed()
end

function FisherClass:destroy_current_loot()
	if self.current_loot and self.current_loot.entity then
		--previously created fish that end up not used
		radiant.entities.destroy_entity(self.current_loot.entity)
		self.current_loot = {}
	end
end

function FisherClass:demote()
	self:destroy_current_loot()

	local player_id = radiant.entities.get_player_id(self._sv._entity)
	local town = stonehearth.town:get_town(player_id)
	if town then
		town:remove_placement_slot_entity(self._sv._entity)
	end

	CraftingJob.demote(self)
end

function FisherClass:destroy()
	self:destroy_current_loot()

	BaseJob.destroy(self)
end

function FisherClass:prepare_next_fish_loot()
	local weighted_set = WeightedSet(rng)
	local fisher_level = self:get_job_level()
	for fish, data in pairs(self.fishing_data) do
		local weight = data.weight or 0
		if type(weight) == 'table' then
			weight = weight["level_"..fisher_level]
		end
		if data.lure_weight_multiplier and data.lure_weight_multiplier[self._sv.current_lure] then
			weight = weight * data.lure_weight_multiplier[self._sv.current_lure]
		end
		local is_valid_biome = self:_is_valid_X( data.is_biome, data.is_not_biome, self.biome_alias )
		local is_valid_kingdom = self:_is_valid_X( data.is_kingdom, data.is_not_kingdom, self.kingdom_alias )
		if weight>0 and is_valid_biome and is_valid_kingdom and self:_is_below_max_fished_limit(data) then
			weighted_set:add(fish, weight)
		end
	end
	local fish_key = weighted_set:choose_random()
	self.current_loot.data = self.fishing_data[fish_key]

	local loot_entity = self:_create_fish_entity(self.current_loot.data)

	self:_set_loot_quality(loot_entity, fisher_level)
	if loot_entity:get_component('stonehearth:stacks') then
		loot_entity:get_component('stonehearth:stacks'):set_stacks(rng:get_int(1,10))
	end
	self.current_loot.entity = loot_entity
end

function FisherClass:_create_fish_entity(fish_data)
	local alias = fish_data.alias
	if type(alias) == 'table' then
		local weighted_set = WeightedSet(rng)
		for uri, valid in pairs(alias) do
			if valid then
				weighted_set:add(uri, 1)
			end
		end
		alias = weighted_set:choose_random()
	end
	return radiant.entities.create_entity(alias, {owner = self._sv._entity})
end

function FisherClass:_set_loot_quality(loot_entity, fisher_level)
	local spirit = radiant.entities.get_attribute(self._sv._entity, "spirit")
	-- worst case, lvl_1 spirit_1 = 0.333% chance
	-- best case, lvl_6 spirit_6 = 12% chance
	local quality_threshold = (fisher_level * spirit) / 300
	local chance = rng:get_real(0, 1)
	local quality_level = 1
	if quality_threshold > chance then
		--got fine quality
		quality_level = quality_level +1
		chance = rng:get_real(0, 1)
		if quality_threshold > chance then
			--got excelent quality
			quality_level = quality_level +1
		end
	end
	loot_entity:add_component('stonehearth:item_quality')
	:initialize_quality(quality_level,nil,nil,{override_allow_variable_quality=true})
end

function FisherClass:_is_below_max_fished_limit(data)
	if not data.max_limit then
		return true
	end
	assert(not (type(data.alias) == 'table'), "'max_limit' can't be used with a list of aliases")
	local quantity = self.town_fished[data.alias] and self.town_fished[data.alias].quantity or 0
	return data.max_limit > quantity
end

function FisherClass:_is_valid_X(is_X, is_not_X, X_alias)
	--X = biome or kingdom. E.g. is_X = is_biome
	local function has_filter( key, value )
		local valid = false
		for i,v in ipairs(key) do
			if v == value then
				valid = true
				break
			end
		end
		return valid
	end
	if (not is_X) and (not is_not_X) then
		--no restriction
		return true
	end
	if is_X then
		--has to match the current alias
		return has_filter(is_X, X_alias)
	end
	if is_not_X then
		--can't match the current alias
		return not has_filter(is_not_X, X_alias)
	end
end

function FisherClass:_create_listeners()
	CraftingJob._create_listeners(self)
	self._xp_listeners = {}

	table.insert(self._xp_listeners, radiant.events.listen(self._sv._entity, 'stonehearth:gather_renewable_resource', self, self._on_renewable_resource_gathered))
	table.insert(self._xp_listeners, radiant.events.listen(self._sv._entity, 'archipelago_biome:got_a_fish', self, self._on_got_a_fish))
end

function FisherClass:_remove_listeners()
	CraftingJob._remove_listeners(self)
	if self._xp_listeners then
		for i, listener in ipairs(self._xp_listeners) do
			listener:destroy()
		end
		self._xp_listeners = nil
	end
end

function FisherClass:_on_renewable_resource_gathered(args)
	if args.harvested_target then
		if self._xp_rewards["harvested_target"][args.harvested_target:get_uri()] then
			self._job_component:add_exp(self._xp_rewards["harvested_target"][args.harvested_target:get_uri()])
		else
			self._job_component:add_exp(self._xp_rewards["harvested_target"]["renewables"])
		end
	end
	if args.spawned_item and self._xp_rewards["spawned_item"][args.spawned_item:get_uri()] then
		self._job_component:add_exp(self._xp_rewards["spawned_item"][args.spawned_item:get_uri()])
	end

	if args.harvested_target:get_uri() == "archipelago_biome:gizmos:crab_trap" then
		self:_got_a_crab(args.harvested_target)
		stonehearth.ai:reconsider_entity(args.harvested_target)
	end

	if args.spawned_item then
		local uri = args.spawned_item:get_uri()
		if not self.town_fished[uri] then
			self.town_fished[uri] = {
				quantity = 0
			}
		end
		self.town_fished[uri].quantity = self.town_fished[uri].quantity +1
	end
end

function FisherClass:_got_a_crab(crab_trap)
	local crab_spawner = crab_trap:get_component('archipelago_biome:crab_spawner')
	crab_spawner:harvestable(false)

	local ec = crab_trap:get_component("entity_container")
	if ec then
		for id, child in ec:each_child() do
			ec:remove_child(id)
			radiant.entities.kill_entity(child)
			radiant.effects.run_effect(crab_trap, "stonehearth:effects:abilities:snare_trap")

			return
		end
	end
end

function FisherClass:_on_got_a_fish()
	local uri = self.current_loot.entity:get_uri()
	if not self.town_fished[uri] then
		self.town_fished[uri] = {
			quantity = 0
		}
	end
	self.town_fished[uri].quantity = self.town_fished[uri].quantity +1

	if self.current_loot.data.max_limit then
		self.town_fished[uri].max_limit = self.current_loot.data.max_limit
	end

	if self.current_loot.data.bulletin then
		stonehearth.bulletin_board:post_bulletin(self.player_id)
		:set_ui_view('ArchipelagoFisherBulletinDialog')
		:set_data({
			zoom_to_entity = self.current_loot.entity,
			title = self.current_loot.data.bulletin.title,
			message = self.current_loot.data.bulletin.message,
			image = self.current_loot.data.bulletin.image
		})
	end

	local xp = self.current_loot.data.xp or 1
	if type(xp) == 'table' then
		xp = xp["level_"..self:get_job_level()]
	end
	self._job_component:add_exp(xp)

	self:prepare_next_fish_loot()
end

function FisherClass:get_current_loot()
	return self.current_loot
end

function FisherClass:fishing_options()
	local commands_component = self._sv._entity:add_component("stonehearth:commands")
	local lure_command = 'archipelago_biome:commands:fishing_default'
	if self._sv.current_lure then
		lure_command = lure_switch[self._sv.current_lure].remove_command
	end
	commands_component:add_command(lure_command)
end
function FisherClass:remove_fishing_options()
	local commands_component = self._sv._entity:get_component("stonehearth:commands")
	if commands_component then
		commands_component:remove_command(lure_switch[self._sv.current_lure].remove_command)
	end
end

function FisherClass:swap_fishing_options()
	local commands_component = self._sv._entity:get_component("stonehearth:commands")
	commands_component:remove_command(lure_switch[self._sv.current_lure].remove_command)
	commands_component:add_command(lure_switch[self._sv.current_lure].add_command)
	self._sv.current_lure = lure_switch[self._sv.current_lure].switch_to_new_lure
end

function FisherClass:debug_fish_loot()
	-- spawn every single loot possible, no matter the conditions
	-- also prints everything in the log
	-- so we can quickly know if one of them have bugs (usually uri typos)

	-- for quick debugging, (while fisher selected) paste on lua console:
	-- e:get_component('stonehearth:job'):get_curr_job_controller():debug_fish_loot()
	local location = radiant.entities.get_world_grid_location(self._sv._entity)
	for fish, data in pairs(self.fishing_data) do
		print("---")
		print("Fish key: "..fish)
		local alias = data.alias
		if type(alias) == 'table' then
			for uri, valid in pairs(alias) do
				print(uri)
				local loot = radiant.entities.create_entity(uri, {owner = self._sv._entity})
				radiant.terrain.place_entity(loot, location)
			end
		elseif alias then
			print(alias)
			local loot = radiant.entities.create_entity(alias, {owner = self._sv._entity})
			radiant.terrain.place_entity(loot, location)
		end
	end
end

return FisherClass