local CustomResourceCallHandler = class()

function CustomResourceCallHandler:harvest_entity(session, response, entity, from_harvest_tool)
	local mod_name = stonehearth.world_generation:get_biome_alias()
	--mod_name is the mod that has the current biome
	local colon_pos = string.find (mod_name, ":", 1, true) or -1
	mod_name = "harvest_entity_" .. string.sub (mod_name, 1, colon_pos-1)
	if self[mod_name]~=nil then
		self[mod_name](self,session, response, entity, from_harvest_tool)
	else
		self:harvest_entity_original(session, response, entity, from_harvest_tool)
	end
end

function CustomResourceCallHandler:harvest_entity_original(session, response, entity, from_harvest_tool)
	local town = stonehearth.town:get_town(session.player_id)

	local renewable_resource_node = entity:get_component('stonehearth:renewable_resource_node')
	local resource_node = entity:get_component('stonehearth:resource_node')

	if renewable_resource_node and renewable_resource_node:get_harvest_overlay_effect() then
		renewable_resource_node:request_harvest(session.player_id)
	elseif resource_node then
		-- check that entity can be harvested using the harvest tool
		if not from_harvest_tool or resource_node:is_harvestable_by_harvest_tool() then
			resource_node:request_harvest(session.player_id)
		end
	end
end

function CustomResourceCallHandler:harvest_entity_archipelago_biome(session, response, entity, from_harvest_tool)
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