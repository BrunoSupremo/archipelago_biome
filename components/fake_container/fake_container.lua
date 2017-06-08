local ArchipelagoFakeContainer = class()

function ArchipelagoFakeContainer:destroy()
	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		return
	end
	--chose the amount to spawn based on difficult
	local difficult = 2 --stonehearth:game_mode:normal
	local gamemode = stonehearth.game_creation:get_game_mode()
	if gamemode == "stonehearth:game_mode:peaceful" then
		difficult = 1
	end
	if gamemode == "stonehearth:game_mode:hard" then
		difficult = 3
	end
	local cocoling
	for i=1, difficult do
		-- Create the entity and put it on the ground
		cocoling = radiant.entities.create_entity('archipelago_biome:monsters:cocoling', {owner = "forest"})
		radiant.terrain.place_entity_at_exact_location(cocoling, location)
	end

	-- local miranda = radiant.entities.create_entity("archipelago_biome:captain_miranda", { owner = "human_npcs" })
	-- radiant.entities.set_custom_name(miranda, "i18n(archipelago_biome:data.gm.campaigns.archipelago.common.captain_miranda)")
	-- local outfit = radiant.entities.create_entity('stonehearth:outfits:trader_outfit')
	-- local hat = radiant.entities.create_entity('archipelago_biome:outfit:tricorn_hat')
	-- miranda:add_component('stonehearth:job')
	-- :promote_to('stonehearth:jobs:npc:worker')
	-- miranda:add_component('stonehearth:equipment')
	-- :equip_item(outfit)
	-- miranda:add_component('stonehearth:equipment')
	-- :equip_item(hat)
	-- radiant.terrain.place_entity_at_exact_location(miranda, location)

	-- local pop = stonehearth.population:get_population("player_1")
	-- local miranda = pop:create_new_citizen("default",'female')
	-- miranda:add_component('stonehearth:job')
	-- :promote_to('stonehearth:jobs:worker')
	-- miranda:add_component('stonehearth:equipment')
	-- :equip_item(outfit)
	-- miranda:add_component('stonehearth:equipment')
	-- :equip_item(hat)
	-- local command_component = miranda:get_component('stonehearth:commands')
	-- if not command_component then
	-- 	return false
	-- end
	-- command_component:remove_command('stonehearth:commands:promote_to_job')
	-- radiant.terrain.place_entity_at_exact_location(miranda, location)
end

return ArchipelagoFakeContainer