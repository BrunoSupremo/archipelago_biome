local Array2D = require 'stonehearth.services.server.world_generation.array_2D'
local SimplexNoise = require 'stonehearth.lib.math.simplex_noise'
local FilterFns = require 'stonehearth.services.server.world_generation.filter.filter_fns'
local PerturbationGrid = require 'stonehearth.services.server.world_generation.perturbation_grid'
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local water_shallow = 'water_1'
local water_deep = 'water_2'
local water_more_deep = 'water_3'
local CustomLandscaper = class()
-- local log = radiant.log.create_logger('meu_log')

function CustomLandscaper:__init(biome, rng, seed)
	local mod_name = stonehearth.world_generation:get_biome_alias()
	--log:error('nome %s', mod_name)
	--mod_name is the mod that has the current biome
	local colon_pos = string.find (mod_name, ":", 1, true) or -1
	mod_name = "__init_" .. string.sub (mod_name, 1, colon_pos-1)
	if self[mod_name]~=nil then
		self[mod_name](self, biome, rng, seed)
	else
		self:__init_original(biome, rng, seed)
	end
end

function CustomLandscaper:__init_original(biome, rng, seed)
	self._biome = biome
	self._tile_width = self._biome:get_tile_size()
	self._tile_height = self._biome:get_tile_size()
	self._feature_size = self._biome:get_feature_block_size()
	self._landscape_info = self._biome:get_landscape_info()
	self._rng = rng
	self._seed = seed

	self._noise_map_buffer = nil
	self._density_map_buffer = nil

	self._perturbation_grid = PerturbationGrid(self._tile_width, self._tile_height, self._feature_size, self._rng)

	self._water_table = {
		water_1 = self._landscape_info.water.depth.shallow,
		water_2 = self._landscape_info.water.depth.deep
	}

	self:_parse_landscape_info()
end

function CustomLandscaper:__init_archipelago_biome(biome, rng, seed)
	self._biome = biome
	self._tile_width = self._biome:get_tile_size()
	self._tile_height = self._biome:get_tile_size()
	self._feature_size = self._biome:get_feature_block_size()
	self._landscape_info = self._biome:get_landscape_info()
	self._rng = rng
	self._seed = seed

	self._noise_map_buffer = nil
	self._density_map_buffer = nil

	self._perturbation_grid = PerturbationGrid(self._tile_width, self._tile_height, self._feature_size, self._rng)

	self._water_table = {
		water_1 = self._landscape_info.water.depth.shallow,
		water_2 = self._landscape_info.water.depth.deep,
		water_3 = self._landscape_info.water.depth.more_deep or self._landscape_info.water.depth.deep
	}

	self:_parse_landscape_info()
end

function CustomLandscaper:mark_water_bodies(elevation_map, feature_map)
	local mod_name = stonehearth.world_generation:get_biome_alias()
	--mod_name is the mod that has the current biome
	local colon_pos = string.find (mod_name, ":", 1, true) or -1
	mod_name = "mark_water_bodies_" .. string.sub (mod_name, 1, colon_pos-1)
	if self[mod_name]~=nil then
		self[mod_name](self, elevation_map, feature_map)
	else
		self:mark_water_bodies_original(elevation_map, feature_map)
	end
end

function CustomLandscaper:mark_water_bodies_original(elevation_map, feature_map)
	local rng = self._rng
	local biome = self._biome
	local config = self._landscape_info.water.noise_map_settings
	local modifier_map, density_map = self:_get_filter_buffers(feature_map.width, feature_map.height)
	--fill modifier map to push water bodies away from terrain type boundaries
	local modifier_fn = function (i,j)
		if self:_is_flat(elevation_map, i, j, 1) then
			return 0
		else
			return -1*config.range
		end
	end
	--use density map as buffer for smoothing filter
	density_map:fill(modifier_fn)
	FilterFns.filter_2D_0125(modifier_map, density_map, modifier_map.width, modifier_map.height, 10)
	--mark water bodies on feature map using density map and simplex noise
	local old_feature_map = Array2D(feature_map.width, feature_map.height)
	for j=1, feature_map.height do
		for i=1, feature_map.width do
			local occupied = feature_map:get(i, j) ~= nil
			if not occupied then
				local elevation = elevation_map:get(i, j)
				local terrain_type = biome:get_terrain_type(elevation)
				local value = SimplexNoise.proportional_simplex_noise(config.octaves,config.persistence_ratio, config.bandlimit,config.mean[terrain_type],config.range,config.aspect_ratio, self._seed,i,j)
				value = value + modifier_map:get(i,j)
				if value > 0 then
					local old_value = feature_map:get(i, j)
					old_feature_map:set(i, j, old_value)
					feature_map:set(i, j, water_shallow)
				end
			end
		end
	end
	self:_remove_juts(feature_map)
	self:_remove_ponds(feature_map, old_feature_map)
	self:_fix_tile_aligned_water_boundaries(feature_map, old_feature_map)
	self:_add_deep_water(feature_map)
end

function CustomLandscaper:mark_water_bodies_archipelago_biome(elevation_map, feature_map)
	local rng = self._rng
	local biome = self._biome
	local config = self._landscape_info.water.noise_map_settings
	local modifier_map, density_map = self:_get_filter_buffers(feature_map.width, feature_map.height)
	--fill modifier map to push water bodies away from terrain type boundaries
	local modifier_fn = function (i,j)
		if self:_is_flat(elevation_map, i, j, 1) then
			return 0
		else
			return -1*config.range
		end
	end
	--use density map as buffer for smoothing filter
	density_map:fill(modifier_fn)
	FilterFns.filter_2D_0125(modifier_map, density_map, modifier_map.width, modifier_map.height, 10)
	--mark water bodies on feature map using density map and simplex noise
	local old_feature_map = Array2D(feature_map.width, feature_map.height)
	for j=1, feature_map.height do
		for i=1, feature_map.width do
			local occupied = feature_map:get(i, j) ~= nil
			if not occupied then
				local elevation = elevation_map:get(i, j)
				local terrain_type = biome:get_terrain_type(elevation)
				local value = SimplexNoise.proportional_simplex_noise(config.octaves,config.persistence_ratio, config.bandlimit,config.mean[terrain_type],config.range,config.aspect_ratio, self._seed,i,j)
				value = value + modifier_map:get(i,j)
				if value > 0 then
					local old_value = feature_map:get(i, j)
					old_feature_map:set(i, j, old_value)
					feature_map:set(i, j, water_shallow)
				end
			end
		end
	end
	self:_remove_juts(feature_map)
	self:_remove_ponds(feature_map, old_feature_map)
	self:_fix_tile_aligned_water_boundaries(feature_map, old_feature_map)
	self:_add_deep_water_archipelago(feature_map)
	self:_add_more_deep_water(feature_map)
	self:_add_more_deep_water_second_pass(feature_map)
end

function CustomLandscaper:_add_deep_water_archipelago(feature_map)
	for j=2, feature_map.height-1 do
		for i=2, feature_map.width-1 do
			local feature_name = feature_map:get(i, j)

			if self:is_water_feature(feature_name) then
				local surrounded_by_water = true

				feature_map:each_neighbor(i, j, false, function(value)
						if not self:is_water_feature(value) then
							surrounded_by_water = false
							return true -- stop iteration
						end
					end)

				if surrounded_by_water then
					feature_map:set(i, j, water_deep)
				end
			end
		end
	end
end

function CustomLandscaper:_add_more_deep_water(feature_map)
	for j=3, feature_map.height-2 do
		for i=3, feature_map.width-2 do
			local feature_name = feature_map:get(i, j)

			if self:is_not_shallow_water_feature(feature_name) then
				local surrounded_by_deep_water = true

				feature_map:each_neighbor(i, j, false, function(value)
						if not self:is_not_shallow_water_feature(value) then
							surrounded_by_deep_water = false
							return true -- stop iteration
						end
					end)

				if surrounded_by_deep_water then
					feature_map:set(i, j, water_more_deep)
				end
			end
		end
	end
end

function CustomLandscaper:_add_more_deep_water_second_pass(feature_map)
	local copy_feature_map = feature_map:clone()
	for j=3, feature_map.height-2 do
		for i=3, feature_map.width-2 do
			local feature_name = feature_map:get(i, j)

			if self:is_exactly_deep_water_feature(feature_name) then
				local number_of_neighbors = 0

				feature_map:each_neighbor(i, j, true, function(value)
						if self:is_exactly_deep_water_feature(value) then
							number_of_neighbors = number_of_neighbors+1
						end
					end)

				if number_of_neighbors>=3 then
					copy_feature_map:set(i, j, water_more_deep)
				end
			end
		end
	end
	for j=3, feature_map.height-2 do
		for i=3, feature_map.width-2 do
			feature_map:set(i, j, copy_feature_map:get(i,j))
		end
	end
end

function CustomLandscaper:is_water_feature(feature_name)
	local mod_name = stonehearth.world_generation:get_biome_alias()
	--mod_name is the mod that has the current biome
	local colon_pos = string.find (mod_name, ":", 1, true) or -1
	mod_name = "is_water_feature_" .. string.sub (mod_name, 1, colon_pos-1)
	if self[mod_name]~=nil then
		return self[mod_name](self, feature_name)
	else
		return self:is_water_feature_original(feature_name)
	end
end

function CustomLandscaper:is_water_feature_original(feature_name)
	return self._water_table[feature_name] ~= nil
end

function CustomLandscaper:is_water_feature_archipelago_biome(feature_name)
	return self._water_table[feature_name] ~= nil
end

function CustomLandscaper:is_not_shallow_water_feature(feature_name)
	if feature_name == nil then
		return false
	end

	local result = feature_name == water_deep or feature_name == water_more_deep
	return result
end

function CustomLandscaper:is_exactly_deep_water_feature(feature_name)
	if feature_name == nil then
		return false
	end

	local result = feature_name == water_deep
	return result
end

--- water spawning
function CustomLandscaper:place_features(tile_map, feature_map, place_item)
	local mod_name = stonehearth.world_generation:get_biome_alias()
	--mod_name is the mod that has the current biome
	local colon_pos = string.find (mod_name, ":", 1, true) or -1
	mod_name = "place_features_" .. string.sub (mod_name, 1, colon_pos-1)
	if self[mod_name]~=nil then
		self[mod_name](self,tile_map, feature_map, place_item)
	else
		self:place_features_original(tile_map, feature_map, place_item)
	end
end

function CustomLandscaper:place_features_original(tile_map, feature_map, place_item)
	for j=1, feature_map.height do
		for i=1, feature_map.width do
			local feature_name = feature_map:get(i, j)
			self:_place_feature(feature_name, i, j, tile_map, place_item)
		end
	end
end

function CustomLandscaper:place_features_archipelago_biome(tile_map, feature_map, place_item)
	local water_1_table = WeightedSet(self._rng)
	for item, weight in pairs(self._landscape_info.water.spawn_objects.water_1) do
		water_1_table:add(item,weight)
	end
	local water_2_table = WeightedSet(self._rng)
	for item, weight in pairs(self._landscape_info.water.spawn_objects.water_2) do
		water_2_table:add(item,weight)
	end
	local water_3_table = WeightedSet(self._rng)
	for item, weight in pairs(self._landscape_info.water.spawn_objects.water_3) do
		water_3_table:add(item,weight)
	end

	local new_feature
	for j=1, feature_map.height do
		for i=1, feature_map.width do
			local feature_name = feature_map:get(i, j)
			if feature_name == "water_1" then
				new_feature = water_1_table:choose_random()
				if new_feature ~= "none" then
					feature_name = new_feature
				end
			end
			if feature_name == "water_2" then
				new_feature = water_2_table:choose_random()
				if new_feature ~= "none" then
					feature_name = new_feature
				end
			end
			if feature_name == "water_3" then
				new_feature = water_3_table:choose_random()
				if new_feature ~= "none" then
					feature_name = new_feature
				end
			end
			self:_place_feature(feature_name, i, j, tile_map, place_item)
		end
	end
end

return CustomLandscaper
