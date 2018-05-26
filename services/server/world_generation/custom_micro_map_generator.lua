local CustomMicroMapGenerator = class()

function CustomMicroMapGenerator:_quantize(micro_map)
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