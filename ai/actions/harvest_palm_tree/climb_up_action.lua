local Entity = _radiant.om.Entity
local Point3 = _radiant.csg.Point3

local Climb_Up_Palm_tree = radiant.class()
Climb_Up_Palm_tree.name = 'climb up palm tree'
Climb_Up_Palm_tree.does = 'archipelago_biome:climb_up'
Climb_Up_Palm_tree.args = {
	path = "table",--instructions
	resource = Entity--palm tree
}
Climb_Up_Palm_tree.priority = 1

function Climb_Up_Palm_tree:_destroy_gameloop_trace()
	if self._gameloop_trace then
		self._gameloop_trace:destroy()
		self._gameloop_trace = nil
	end
end

function Climb_Up_Palm_tree:_get_vector_to_target(target_position)
	local climber_location = self._mob:get_world_location()
	local vector = target_position - climber_location
	return vector
end

function Climb_Up_Palm_tree:_get_distance_per_gameloop()
	return 0.1 * stonehearth.game_speed:get_game_speed()
end

function Climb_Up_Palm_tree:get_tree_coord(offset)
	local facing = self._mob_tree:get_facing()
	local location = self._mob_tree:get_world_grid_location() + Point3(0,offset.y,0)
	return location + radiant.math.rotate_about_y_axis(Point3.unit_x*offset.x, facing):to_closest_int()
end

function Climb_Up_Palm_tree:run(ai, entity, args)
	self._mob = entity:add_component('mob')
	self._mob_tree = args.resource:add_component('mob')
	self._mob:move_to( self:get_tree_coord(args.path[1]) )
	self._mob:turn_to_face_point(self:get_tree_coord({x=0,y=0}))
	for i=2, #args.path do
		local target_position = self:get_tree_coord(args.path[i])
		local outer_vector = self:_get_vector_to_target(target_position)
		local outer_distance = outer_vector:length()
		self._gameloop_trace = radiant.on_game_loop('climbing movement', function()
			if not args.resource:is_valid() then
				self:_destroy_gameloop_trace()
				return
			end

			local vector = self:_get_vector_to_target(target_position)
			local distance = vector:length()
			local move_distance = self:_get_distance_per_gameloop()

			if distance < move_distance then
				self:_destroy_gameloop_trace()
				vector:normalize()
				vector:scale(move_distance)

				local climber_location = self._mob:get_world_location()
				local new_climber_location = climber_location + vector

				self._mob:move_to(new_climber_location)
				return
			end

			vector:normalize()
			vector:scale(move_distance)

			local climber_location = self._mob:get_world_location()
			local new_climber_location = climber_location + vector

			self._mob:move_to(new_climber_location)
			end)
		local effect = "run"
		if i%2==0 then
			effect = "run_climb_ladder_up"
		end
		ai:execute('stonehearth:run_effect_timed', { effect = effect, duration = outer_distance.."m" })
	end
	self.succeded = true
end

function Climb_Up_Palm_tree:stop(ai, entity, args)
	self:_destroy_gameloop_trace()
	if not self.succeded then
		local entity_location = radiant.entities.get_world_grid_location(entity)
		local tree_location = radiant.entities.get_world_grid_location(args.resource) or entity_location
		if entity_location.y ~= tree_location.y then
			radiant.entities.move_to(entity, tree_location)
		end
	end
end

return Climb_Up_Palm_tree