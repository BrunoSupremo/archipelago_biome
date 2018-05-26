local CustomResourceCallHandler = class()
local validator = radiant.validator

function CustomResourceCallHandler:harvest_entity(session, response, entity, from_harvest_tool)
	validator.expect_argument_types({'Entity', validator.optional('boolean')}, entity, from_harvest_tool)

	local town = stonehearth.town:get_town(session.player_id)

	local renewable_resource_node = entity:get_component('stonehearth:renewable_resource_node')
	local resource_node = entity:get_component('stonehearth:resource_node')

	if renewable_resource_node and renewable_resource_node:get_harvest_overlay_effect() and renewable_resource_node:is_harvestable() then
		renewable_resource_node:request_harvest(session.player_id)
	elseif resource_node then
		-- check that entity can be harvested using the harvest tool
		if not from_harvest_tool or resource_node:is_harvestable_by_harvest_tool() then
			resource_node:request_harvest(session.player_id)
		end
	end
end

return CustomResourceCallHandler