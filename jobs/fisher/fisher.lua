local CraftingJob = require 'stonehearth.jobs.crafting_job'
local BaseJob = require 'stonehearth.jobs.base_job'
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local rng = _radiant.math.get_default_rng()

local FisherClass = class()
radiant.mixin(FisherClass, CraftingJob)

function FisherClass:initialize()
	CraftingJob.initialize(self)
	self._sv.fished = {}
	self._sv.current_loot = nil
	self._sv.current_fish = nil --deprecated
end

function FisherClass:restore()
	if self._sv.is_current_class then
		self:_register_with_town()
	end
end

function FisherClass:activate()
	BaseJob.activate(self)
	self.biome_alias = stonehearth.world_generation:get_biome_alias()
	self.player_id = radiant.entities.get_player_id(self._sv._entity)
	self.kingdom_alias = stonehearth.player:get_kingdom(self.player_id)
	if self._sv.is_current_class then
		self:_register_with_town()
	end
	self.fishing_data = radiant.resources.load_json("archipelago_biome:data:fishing", true, false)
	self:prepare_next_fish_loot()

	--deprecated
	if self._sv.current_fish then
		radiant.entities.destroy_entity(self._sv.current_fish)
		self._sv.current_fish = nil
	end
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
	end
	self.__saved_variables:mark_changed()
end

function FisherClass:destroy_current_loot()
	if self._sv.current_loot then
		--previously created fish that end up not used
		radiant.entities.destroy_entity(self._sv.current_loot.entity)
		self._sv.current_loot = nil
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

function FisherClass:prepare_next_fish_loot()
	local weighted_set = WeightedSet(rng)
	local level = "level_"..self:get_job_level()
	if not self.fishing_data[level] then
		level = "level_1"
	end
	for fish, table in pairs(self.fishing_data[level]) do
		local weight = table.weight or 0
		local is_valid_biome = self:_is_valid_X( table.is_biome, table.is_not_biome, self.biome_alias )
		local is_valid_kingdom = self:_is_valid_X( table.is_kingdom, table.is_not_kingdom, self.kingdom_alias )
		local is_below_limit = not table.max_limit or table.max_limit>(self._sv.fished[table.alias] or 0)
		if weight>0 and is_valid_biome and is_valid_kingdom and is_below_limit then
			weighted_set:add(fish, weight)
		end
	end
	local fish_key = weighted_set:choose_random()
	self._sv.current_loot = self.fishing_data[level][fish_key]

	local loot_entity = radiant.entities.create_entity(self.fishing_data[level][fish_key].alias, {owner = self._sv._entity})
	if loot_entity:get_component('stonehearth:stacks') then
		loot_entity:get_component('stonehearth:stacks'):set_stacks(rng:get_int(1,10))
	end
	local entity_forms = loot_entity:get_component('stonehearth:entity_forms')
	if entity_forms then
		local iconic_entity = entity_forms:get_iconic_entity()
		if iconic_entity then
			loot_entity = iconic_entity
		end
	end
	self._sv.current_loot.entity = loot_entity
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
	if args.spawned_item then
		self._job_component:add_exp(self._xp_rewards["spawned_item"][args.spawned_item:get_uri()])
	end

	if args.harvested_target:get_uri() == "archipelago_biome:gizmos:crab_trap" then
		self:_got_a_crab(args.harvested_target)
		stonehearth.ai:reconsider_entity(args.harvested_target)
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
	self._sv.fished[self._sv.current_loot.alias] = (self._sv.fished[self._sv.current_loot.alias] or 0) +1

	if self._sv.current_loot.bulletin then
		stonehearth.bulletin_board:post_bulletin(self.player_id)
		:set_ui_view('ArchipelagoFisherBulletinDialog')
		:set_data({
			zoom_to_entity = self._sv.current_loot.entity,
			title = self._sv.current_loot.bulletin.title,
			message = self._sv.current_loot.bulletin.message,
			image = self._sv.current_loot.bulletin.image
		})
	end

	local xp = self._sv.current_loot.xp or 1
	self._job_component:add_exp(xp)

	self:prepare_next_fish_loot()
end

function FisherClass:get_current_loot()
	return self._sv.current_loot
end

return FisherClass