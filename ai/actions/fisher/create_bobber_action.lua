local FishingCreateBobbber = class()
local Point3 = _radiant.csg.Point3
local Entity = _radiant.om.Entity

FishingCreateBobbber.name = 'create bobber'
FishingCreateBobbber.does = 'archipelago_biome:create_bobber'
FishingCreateBobbber.args = {}
FishingCreateBobbber.version = 2
FishingCreateBobbber.priority = 1

FishingCreateBobbber.think_output = {
	bobber = Entity
}

function FishingCreateBobbber:start_thinking(ai, entity, args)
	self._bobber = radiant.entities.create_entity("archipelago_biome:fisher:bobber")
	ai:set_think_output({bobber = self._bobber})
end

function FishingCreateBobbber:run(ai, entity, args)
	local mob = entity:get_component('mob')
	local facing = mob:get_facing()
	local location = mob:get_world_location()
	local offset = radiant.math.rotate_about_y_axis(-Point3.unit_z*4, facing)
	location.y = math.min(_physics:get_standable_point(entity, location+offset).y, location.y)
	radiant.terrain.place_entity_at_exact_location(self._bobber, location + offset)
	self._bobber:get_component("archipelago_biome:need_water"):float_now_called_from_ai()
end

function FishingCreateBobbber:stop(ai, entity, args)
	self:_destroy_bobber()
end

function FishingCreateBobbber:destroy(ai, entity, args)
	self:_destroy_bobber()
end

function FishingCreateBobbber:_destroy_bobber()
	if self._bobber then
		radiant.entities.destroy_entity(self._bobber)
	end
end

return FishingCreateBobbber