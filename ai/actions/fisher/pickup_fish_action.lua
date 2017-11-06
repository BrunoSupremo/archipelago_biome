local Entity = _radiant.om.Entity
local PickUpFish = class()

PickUpFish.name = 'create and grab the fish'
PickUpFish.does = 'archipelago_biome:pickup_fish'
PickUpFish.args = {
location = Entity
}
PickUpFish.think_output = {
fish = Entity
}
PickUpFish.version = 2
PickUpFish.priority = 1

function PickUpFish:start_thinking(ai, entity, args)
	self.fish = radiant.entities.create_entity("archipelago_biome:food:fish", {owner = entity})
	if not ai.CURRENT.carrying then
		ai.CURRENT.carrying = self.fish
		ai:set_think_output({fish = self.fish})
	end
end

function PickUpFish:run(ai, entity, args)
	local location = radiant.entities.get_world_grid_location(args.location)
	radiant.terrain.place_entity_at_exact_location(self.fish, location)
	radiant.check.is_entity(self.fish)

	if stonehearth.ai:prepare_to_pickup_item(ai, entity, self.fish) then
		return
	end
	assert(not radiant.entities.get_carrying(entity))

	if not radiant.entities.is_adjacent_to(entity, self.fish) then
		ai:abort(string.format('%s is not adjacent to %s', tostring(entity), tostring(self.fish)))
		return
	end

	radiant.entities.turn_to_face(entity, self.fish, true)
	stonehearth.ai:pickup_item(ai, entity, self.fish, args.relative_orientation)
	ai:execute('stonehearth:run_pickup_effect', { location = location })
	radiant.events.trigger_async(entity, 'stonehearth:gather_resource', {harvested_target = self.fish})
end

return PickUpFish