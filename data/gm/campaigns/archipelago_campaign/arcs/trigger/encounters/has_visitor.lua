local HasVisitorsSpawned = class()
local log = radiant.log.create_logger('HasVisitorsSpawned')

function HasVisitorsSpawned:start(ctx, info)
	local target_entities = radiant.map_to_array(ctx.entity_registration_paths)

	for i, entity_name in ipairs(target_entities) do
		local target = ctx:get(entity_name)
		log:error(target)
	end
	log:error(ctx:get("visitors.raft"))
	
	if ctx:get("visitors.raft") then
		return true
	end

	return false
end

return HasVisitorsSpawned