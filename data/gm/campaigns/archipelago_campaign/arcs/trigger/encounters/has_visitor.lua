local HasVisitorsSpawned = class()
-- local log = radiant.log.create_logger('HasVisitorsSpawned')

function HasVisitorsSpawned:start(ctx, info)
	local raft = ctx:get("visitors.raft")
	if raft then
		return true
	end

	return false
end

return HasVisitorsSpawned