local HasVisitorsSpawned = class()

function HasVisitorsSpawned:start(ctx, info)
	local parent_node = ctx:get_data().parent_node
	if parent_node then
		local raft = parent_node:get_ctx():get("visitors.female_3")
		if raft then
			return true
		end
	end

	return false
end

return HasVisitorsSpawned