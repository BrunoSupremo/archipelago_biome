local ArchipelagoSeasonsService = class()

local DEFAULT_WEATHER = 'stonehearth:weather:sunny'
local CALENDAR_CONSTANTS = radiant.resources.load_json('/stonehearth/data/calendar/calendar_constants.json')
local DAYS_PER_YEAR = CALENDAR_CONSTANTS.days_per_month * CALENDAR_CONSTANTS.months_per_year
local SECONDS_PER_DAY = CALENDAR_CONSTANTS.hours_per_day * CALENDAR_CONSTANTS.minutes_per_hour * CALENDAR_CONSTANTS.seconds_per_minute

local terrain_blocks = radiant.resources.load_json("stonehearth:terrain_blocks", true, false)

function ArchipelagoSeasonsService:_load_season_config(biome_uri)
	self._seasons = {}

	local biome = radiant.resources.load_json(biome_uri)
	assert(biome, 'biome not found: ' .. biome_uri)
	local generation_data = radiant.resources.load_json(biome.generation_file)
	assert(generation_data and generation_data.palettes, 'biome generation_data not found in ' .. biome_uri)
	local default_palette = generation_data.season and generation_data.palettes[generation_data.season] or generation_data.palettes[next(generation_data.palettes)]

	if biome.seasons then
		for id, season_config in pairs(biome.seasons) do
			assert(season_config.start_day and season_config.start_day >= 0 and season_config.start_day < DAYS_PER_YEAR,
				'Must specify season start day between 0 and ' .. tostring(DAYS_PER_YEAR))
			table.insert(self._seasons, {
				id = id,
				display_name = season_config.display_name,
				description = season_config.description,
				start_day = season_config.start_day,
				biome = biome_uri,
				weather = season_config.weather,
				terrain_palette = generation_data.palettes[id] or default_palette
			})
		end
	elseif biome.weather then
		table.insert(self._seasons, {
			id = 'default',
			display_name = '',
			description = '',
			start_day = 0,
			biome = biome_uri,
			weather = biome.weather,
			terrain_palette = default_palette,
		})
	else
		table.insert(self._seasons, {
			id = 'default',
			display_name = '',
			description = '',
			start_day = 0,
			biome = biome_uri,
			weather = { { uri = DEFAULT_WEATHER, weight = 1 } },
			terrain_palette = default_palette,
		})
	end

	for _, season in ipairs(self._seasons) do
		for block, color in pairs(terrain_blocks.default_colors) do
			if not season.terrain_palette[block] then
				season.terrain_palette[block] = color
			end
		end
	end

	table.sort(self._seasons, function(a, b)
		return a.start_day < b.start_day
	end)

	for i, season in ipairs(self._seasons) do
		season.end_day = self._seasons[i == #self._seasons and 1 or (i + 1)].start_day
	end

	self._is_in_transition = true
	self:_update_transition()
	radiant.events.listen_once(radiant, 'stonehearth:start_date_set', function(e)
		self._is_in_transition = true
		self:_update_transition()
	end)
	
	self:_resolve_get_seasons_commands(self._get_seasons_futures)
	self._get_seasons_futures = {}

	radiant.events.trigger_async(radiant, 'stonehearth:seasons_set')
end

return ArchipelagoSeasonsService