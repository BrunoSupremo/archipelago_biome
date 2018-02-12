local CustomMicroMapGenerator = class()

function CustomMicroMapGenerator:_quantize(micro_map)
	local biome_name = stonehearth.world_generation:get_biome_alias()
	local colon_position = string.find (biome_name, ":", 1, true) or -1
	local mod_name_containing_the_biome = string.sub (biome_name, 1, colon_position-1)
	local fn = "_quantize_" .. mod_name_containing_the_biome
	if self[fn] ~= nil then
		--found a function for the biome being used, named:
		-- self:_quantize_<biome_name>(args,...)
		self[fn](self, micro_map)
	else
		--there is no function for this specific biome, so call a copy of the original from stonehearth
		self:_quantize_original(micro_map)
	end
end

function CustomMicroMapGenerator:_quantize_original(micro_map)
	local quantizer = self._biome:get_quantizer()
	local plains_max_height = self._terrain_info.plains.height_max

	micro_map:process(
		function (value)
			-- don't quantize below plains_max_height
			-- we have special detailing code for that
			-- could also use a different quantizer for this
			-- currently the same quantizer as the TerrainGenerator
			if value <= plains_max_height then
				return plains_max_height
			end
			return quantizer:quantize(value)
		end
		)
end

function CustomMicroMapGenerator:_quantize_archipelago_biome(micro_map)
	local quantizer = self._biome:get_quantizer()
	local plains_max_height = self._terrain_info.plains.height_max
	local foothills_base = self._terrain_info.foothills.height_base
	local max_height = 85--self._terrain_info.mountains.height_max
	local exp = 10

	micro_map:process(
		function (value)
			if value <= plains_max_height then
				return plains_max_height
			end
			if value <= foothills_base then
				return foothills_base
			end
			return quantizer:quantize(foothills_base + (max_height - foothills_base) * (value^exp - foothills_base^exp) /  (max_height^exp - foothills_base^exp))
			-- return quantizer:quantize(value)

			-- return quantizer:quantize( ((115-value)/70)*45 + value*(1-((115-value)/70)) )
		end
		)
end

return CustomMicroMapGenerator