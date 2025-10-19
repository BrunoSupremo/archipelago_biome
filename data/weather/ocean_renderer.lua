local Point3 = _radiant.csg.Point3
local selector_util = require 'stonehearth.services.client.selection.selector_util'
local rng = _radiant.math.get_default_rng()

local WindyWeatherRenderer = class()

local GUST_INTERVAL = 3  -- in game minutes
local GUST_EFFECTS = 'archipelago_biome:effects:water:glint'

local MAX_POINTS_TO_TRY_PER_SPAWN = 3
local SCREEN_MARGIN = 100

function WindyWeatherRenderer:initialize()
	self._gust_anchor = nil
	self._clock_trace = nil
	self._time_constants = radiant.resources.load_json('/stonehearth/data/calendar/calendar_constants.json')
	self._next_spawn_time = 0         
end

function WindyWeatherRenderer:destroy()
	if self._clock_trace then
		self._clock_trace:destroy()
		self._clock_trace = nil
	end
end

function WindyWeatherRenderer:activate()
	self._gust_anchor = radiant.entities.create_entity('stonehearth:object:transient', { debug_text = 'wind gust effect anchor' })
	radiant.terrain.place_entity_at_exact_location(self._gust_anchor, Point3.zero)

	_radiant.call('stonehearth:get_clock_object'):done(function (o)
		local clock_object = o.clock_object
		self._clock_trace = clock_object:trace_data('drawing water glint')
		:on_changed(function()
			local date = clock_object:get_data()
			if date then
				self:_update_time(date.second + (self._time_constants.seconds_per_minute * (date.minute + (self._time_constants.minutes_per_hour * date.hour))))
			end
		end)
		:push_object_state()
	end)
end

function WindyWeatherRenderer:_update_time(now)
	if now >= self._next_spawn_time or self._next_spawn_time > 86400 then
		if self:_try_spawn_gust() then
			self._next_spawn_time = now + GUST_INTERVAL * self._time_constants.seconds_per_minute
		end
	end
end

function WindyWeatherRenderer:_try_spawn_gust()
	local location
	for _ = 1, MAX_POINTS_TO_TRY_PER_SPAWN do
		-- Select a random spot in the player's view, biased to the center (avg of two rng)
		local x = math.floor( (rng:get_int(SCREEN_MARGIN, 1920 - SCREEN_MARGIN) + rng:get_int(SCREEN_MARGIN, 1920 - SCREEN_MARGIN)) /2)
		local y = math.floor( (rng:get_int(SCREEN_MARGIN, 1080 - SCREEN_MARGIN) + rng:get_int(SCREEN_MARGIN, 1080 - SCREEN_MARGIN)) /2)
		location = selector_util.get_selected_brick(x, y, function(result)
			if result.entity:get_uri() == "stonehearth:terrain:water" then
				return true
			end
			return stonehearth.selection.FILTER_IGNORE
		end)

		if location then
			break  -- Found a good one!
		end
	end

	if location then
		return self:_spawn_gust_at(location)
	else
		return false
	end
end

function WindyWeatherRenderer:_spawn_gust_at(location)
	if not self._gust_anchor then
		return false -- Too early
	end

	local render_entity = _radiant.client.get_render_entity(self._gust_anchor)
	if not render_entity then
		return false  -- Too early
	end

	radiant.entities.move_to(self._gust_anchor, location)

	render_entity:start_client_only_effect(GUST_EFFECTS)

	return true
end

return WindyWeatherRenderer