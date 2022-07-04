local FisherFieldComponent = class()
local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3

function FisherFieldComponent:initialize()
	self._sv.size = nil
end

function FisherFieldComponent:create()
	self._sv.size = Point2.zero
end

function FisherFieldComponent:set_size(x, z)
	self._sv.size = Point2(x, z)
	self.__saved_variables:mark_changed()
end

function FisherFieldComponent:get_water_direction(origin)
	return
	FisherFieldComponent:_get_water_below(origin-Point3.unit_z) or
	FisherFieldComponent:_get_water_below(origin+Point3.unit_z) or
	FisherFieldComponent:_get_water_below(origin-Point3.unit_x) or
	FisherFieldComponent:_get_water_below(origin+Point3.unit_x)
end

function FisherFieldComponent:_get_water_below(neighbor_point)
	local ground_point = radiant.terrain.get_standable_point(neighbor_point)
	local entities_present = radiant.terrain.get_entities_at_point(ground_point)

	for id, entity in pairs(entities_present) do
		local water_component = entity:get_component('stonehearth:water')
		if water_component then
			return neighbor_point
		end
	end
	return false
end

return FisherFieldComponent