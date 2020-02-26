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

local ExtraMapOptions = require 'extra_map_options.services.server.world_generation.landscaper'

function CustomLandscaper:mark_water_bodies(elevation_map, feature_map)
	self._water_table["water_3"] = self._landscape_info.water.depth.more_deep

	if self._extra_map_options_on then
		ExtraMapOptions.mark_water_bodies(self, elevation_map, feature_map)
		self:_add_more_deep_water(feature_map)
		self:_add_more_deep_water_second_pass(feature_map)
	else
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

						local islands_value = SimplexNoise.proportional_simplex_noise(config.octaves,config.persistence_ratio, config.bandlimit,config.mean[terrain_type],config.range,config.aspect_ratio, self._seed,i,j)
						if islands_value > config.range-1 then
							feature_map:set(i, j, self:_spawn_island())
						else
							feature_map:set(i, j, water_shallow)
						end
					end
				end
			end
		end
		self:_remove_juts(feature_map)
		self:_remove_ponds(feature_map, old_feature_map)
		self:_fix_tile_aligned_water_boundaries(feature_map, old_feature_map)
		self:_add_deep_water(feature_map)
		self:_add_more_deep_water(feature_map)
		self:_add_more_deep_water_second_pass(feature_map)
	end
end

function CustomLandscaper:_spawn_island()
	local tree = {
		"archipelago_biome:trees:palm:small",
		"archipelago_biome:trees:palm:large",
		"archipelago_biome:trees:bend_palm:small",
		"archipelago_biome:trees:bend_palm:large"
	}
	return tree[self._rng:get_int(1,4)]
end

function CustomLandscaper:_add_deep_water(feature_map)
	local is_valid_and_has_water = function (i,j)
		if feature_map:in_bounds(i,j) then
			local feature_name = feature_map:get(i, j)
			return self:is_water_feature(feature_name)
		end
		return true --is out of bounds, consider it as having water
	end
	for j=1, feature_map.height do
		for i=1, feature_map.width do
			local feature_name = feature_map:get(i, j)

			if self:is_water_feature(feature_name) then
				if is_valid_and_has_water(i-1, j) and is_valid_and_has_water(i+1, j) and is_valid_and_has_water(i, j-1) and is_valid_and_has_water(i, j+1) then
					feature_map:set(i, j, water_deep)
				end
			end
		end
	end
end

function CustomLandscaper:_add_more_deep_water(feature_map)
	local is_valid_and_has_water = function (i,j)
		if feature_map:in_bounds(i,j) then
			local feature_name = feature_map:get(i, j)
			return self:is_not_shallow_water_feature(feature_name)
		end
		return true --is out of bounds, consider it as having water
	end
	for j=1, feature_map.height do
		for i=1, feature_map.width do
			local feature_name = feature_map:get(i, j)

			if self:is_water_feature(feature_name) then
				if is_valid_and_has_water(i-1, j) and is_valid_and_has_water(i+1, j) and is_valid_and_has_water(i, j-1) and is_valid_and_has_water(i, j+1) then
					feature_map:set(i, j, water_more_deep)
				end
			end
		end
	end
end

function CustomLandscaper:_add_more_deep_water_second_pass(feature_map)
	local copy_feature_map = feature_map:clone()
	for j=2, feature_map.height-1 do
		for i=2, feature_map.width-1 do
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
	for j=2, feature_map.height-1 do
		for i=2, feature_map.width-1 do
			feature_map:set(i, j, copy_feature_map:get(i,j))
		end
	end
end

function CustomLandscaper:is_water_feature(feature_name)
	if feature_name == "water_3" then
		return true
	end
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
