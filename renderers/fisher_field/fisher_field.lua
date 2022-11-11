local ZoneRenderer = require 'stonehearth.renderers.zone_renderer'
local Color4 = _radiant.csg.Color4
local Point2 = _radiant.csg.Point2

local FisherFieldRenderer = class()

function FisherFieldRenderer:initialize(render_entity, datastore)
	self._datastore = datastore

	self._zone_renderer = ZoneRenderer(render_entity)
	:set_designation_colors(Color4(100, 150, 200, 255), Color4(100, 150, 200, 255))
	:set_ground_colors(Color4(50, 75, 100, 10), Color4(50, 75, 100, 30))

	self._datastore_trace = self._datastore:trace_data('rendering fisher field')
	:on_changed(
		function()
			self:_update()
		end
		)
	:push_object_state()
end

function FisherFieldRenderer:destroy()
	if self._datastore_trace then
		self._datastore_trace:destroy()
		self._datastore_trace = nil
	end

	self._zone_renderer:destroy()
end

function FisherFieldRenderer:_update()
	local data = self._datastore:get_data()
	local size = data.size
	local items = {}

	self._zone_renderer:set_size(size)
	self._zone_renderer:set_current_items(items)
end

return FisherFieldRenderer