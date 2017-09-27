archipelago_biome_client = {
constants = require 'constants'
}
local player_service_trace = nil
-- local log = radiant.log.create_logger('not_loading')

local function check_override_ui(players, player_id)
	if not player_id then
		player_id = _radiant.client.get_player_id()
	end

	local client_player = players[player_id]
	if client_player then
		if client_player.kingdom == "rayyas_children:kingdoms:rayyas_children" then
			-- log:error("_radiant.res.apply_manifest")
			_radiant.res.apply_manifest("/archipelago_biome/rayyas_children_selected/manifest.json")
		end
	end
end

local function trace_player_service()
	_radiant.call('stonehearth:get_service', 'player')
	:done(function(r)
		local player_service = r.result
		check_override_ui(player_service:get_data().players)
		player_service_trace = player_service:trace('using rayyas children')
		:on_changed(function(o)
			check_override_ui(player_service:get_data().players)
			end)
		end)
end

radiant.events.listen(archipelago_biome_client, 'radiant:init', function()
	trace_player_service()
	end)

return archipelago_biome_client