local rng = _radiant.math.get_default_rng()
local CustomPopulationFaction = class()

function CustomPopulationFaction:generate_town_name_for_archipelago_biome()
	local composite_name = 'Nameless Island'
	local pieces = self._data.town_pieces.archipelago_town_pieces
	if pieces then
		local prefixes =	pieces.optional_prefix
		local base_names =	pieces.town_name
		local suffix =		pieces.suffix

		local target_prefix = prefixes[rng:get_int(1, #prefixes)]
		local target_base =	base_names[rng:get_int(1, #base_names)]
		local target_suffix =	suffix[rng:get_int(1, #suffix)]

		if target_base then
			composite_name = target_base
		end
		if target_prefix and rng:get_int(1, 100) < 66 then
			composite_name = target_prefix .. ' ' .. composite_name
		end
		if target_suffix then
			composite_name = composite_name .. ' ' .. target_suffix
		end
	end

	return composite_name
end

return CustomPopulationFaction