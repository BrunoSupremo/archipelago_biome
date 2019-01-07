local ArchipelagoExplosive = class()
local Point3 = _radiant.csg.Point3
local Region3 = _radiant.csg.Region3

function ArchipelagoExplosive:activate()
	self._on_kill_listener = radiant.events.listen(self._entity, 'stonehearth:kill_event', function(args)
		self:kill()
		self._on_kill_listener = nil
		end)
end

function ArchipelagoExplosive:destroy()
	if self._on_kill_listener then
		self._on_kill_listener:destroy()
		self._on_kill_listener = nil
	end
end

function ArchipelagoExplosive:kill()
	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		return
	end

	local region = Region3()
	region:add_point(location)
	region = region:inflated(Point3(7,7,7))
	local entities = radiant.terrain.get_entities_in_region(region)
	for _, entity in pairs(entities) do
		local is_hostile = stonehearth.player:are_entities_hostile(entity, self._entity)
		if is_hostile and radiant.entities.has_free_will(entity) then
			radiant.entities.modify_health(entity, -250)
			radiant.entities.add_buff(entity, "stonehearth:buffs:archer:fire_arrow")
			radiant.entities.add_buff(entity, "stonehearth:buffs:archer:slowing_arrow")
		end
	end
end

return ArchipelagoExplosive