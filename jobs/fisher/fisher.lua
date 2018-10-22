--I do not give consent to copy this
local CraftingJob = require 'stonehearth.jobs.crafting_job'
local BaseJob = require 'stonehearth.jobs.base_job'
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local rng = _radiant.math.get_default_rng()

local FisherClass = class()
radiant.mixin(FisherClass, CraftingJob)

function FisherClass:initialize()
	CraftingJob.initialize(self)
	self._sv.fished = {}
	self._sv.current_fish = nil
end

function FisherClass:activate()
	BaseJob.activate(self)
	self.fishing_data = radiant.resources.load_json("archipelago_biome:data:fishing", true)
	self.biome_alias = stonehearth.world_generation:get_biome_alias()
	self.player_id = radiant.entities.get_player_id(self._sv._entity)
	self.kingdom_alias = stonehearth.player:get_kingdom(self.player_id)
end

function FisherClass:chose_random_fish()
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
	local weighted_set = WeightedSet(rng)
	local level = "level_"..self:get_job_level()
	if not (self.fishing_data and self.fishing_data[level]) then
		return nil
	end
	for fish, table in pairs(self.fishing_data[level]) do
		local weight = table.weight or 0
		local is_valid_biome = not table.is_biome_exclusive or has_filter(table.is_biome_exclusive, self.biome_alias)
		local is_valid_kingdom = not table.is_kingdom_exclusive or has_filter(table.is_kingdom_exclusive, self.kingdom_alias)
		local is_below_limit = not table.max_limit or table.max_limit>(self._sv.fished[level..fish] or 0)
		if weight>0 and is_valid_biome and is_valid_kingdom and is_below_limit then
			weighted_set:add(fish, weight)
		end
	end
	if weighted_set:is_empty() then
		return nil
	end
	local fish_key = weighted_set:choose_random()
	self.current_fish_key = fish_key
	return self.fishing_data[level][fish_key]
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

	if self._crab_trapped_listener then
		self._crab_trapped_listener:destroy()
		self._crab_trapped_listener = nil
	end
end

function FisherClass:_on_renewable_resource_gathered(args)
	if args.harvested_target then
		self._job_component:add_exp(1) --base exp for any renewable harvest
	end

	if args.harvested_target:get_uri() == "archipelago_biome:beach:oyster" then
		self._job_component:add_exp(10) --extra for oysters

		if args.spawned_item:get_uri() == "archipelago_biome:resources:pearl:black" then
			self._job_component:add_exp(5) --another extra for black pearls
		end
	end

	if args.harvested_target:get_uri() == "archipelago_biome:gizmos:crab_trap" then
		stonehearth.ai:reconsider_entity(args.harvested_target)
		self:_got_a_crab(args.harvested_target)
		self._job_component:add_exp(10) --extra for crabs traps
	end
end

function FisherClass:_got_a_crab(crab_trap)
	local rsc = crab_trap:get_component('stonehearth:renewable_resource_node')
	rsc:pause_resource_timer()

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

function FisherClass:remember_current_fish(fish)
	if self._sv.current_fish then
		--previously created fish that end up not used
		radiant.entities.destroy_entity(self._sv.current_fish)
	end
	self._sv.current_fish = fish
	self.__saved_variables:mark_changed()
end

function FisherClass:clear_current_fish()
	self._sv.current_fish = nil
	self.__saved_variables:mark_changed()
end

function FisherClass:_on_got_a_fish(args)
	local fish_key = self.current_fish_key
	local level = "level_"..self:get_job_level()
	self._sv.fished[level..fish_key] = (self._sv.fished[level..fish_key] or 0) +1
	self.__saved_variables:mark_changed()

	if self.fishing_data[level][fish_key].bulletin then
		stonehearth.bulletin_board:post_bulletin(self.player_id)
		:set_ui_view('ArchipelagoFisherBulletinDialog')
		:set_data({
			zoom_to_entity = args.the_fish,
			title = self.fishing_data[level][fish_key].bulletin.title,
			message = self.fishing_data[level][fish_key].bulletin.message,
			image = self.fishing_data[level][fish_key].bulletin.image
			})
	end

	local xp = self.fishing_data[level][fish_key].xp or 1
	self._job_component:add_exp(xp)

	self:clear_current_fish()
end

return FisherClass