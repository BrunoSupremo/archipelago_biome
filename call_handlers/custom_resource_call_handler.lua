local CustomResourceCallHandler = class()

function CustomResourceCallHandler:harvest_entity(session, response, entity, from_harvest_tool)
	local biome_name = stonehearth.world_generation:get_biome_alias()
	local colon_position = string.find (biome_name, ":", 1, true) or -1
	local mod_name_containing_the_biome = string.sub (biome_name, 1, colon_position-1)
	local fn = "harvest_entity_" .. mod_name_containing_the_biome
	if self[fn] ~= nil then
		--found a function for the biome being used, named:
		-- self:harvest_entity_<biome_name>(args,...)
		self[fn](self, session, response, entity, from_harvest_tool)
	else
		--there is no function for this specific biome, so call a copy of the original from stonehearth
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