local Entity = _radiant.om.Entity
local Point3 = _radiant.csg.Point3

local Climb_Down_Palm_tree = radiant.class()
Climb_Down_Palm_tree.name = 'climb down palm tree'
Climb_Down_Palm_tree.does = 'archipelago_biome:climb_down'
Climb_Down_Palm_tree.args = {
	path = "table",--instructions
	resource = Entity--palm tree
}
Climb_Down_Palm_tree.priority = 1
local log = radiant.log.create_logger('bugged')
function Climb_Down_Palm_tree:_destroy_gameloop_trace()
	if self._gameloop_trace then
		self._gameloop_trace:destroy()
		self._gameloop_trace = nil
	end
end

function Climb_Down_Palm_tree:_get_vector_to_target(target_position)
	local climber_location = self._mob:get_world_location()
	local vector = target_position - climber_location
	return vector
end

function Climb_Down_Palm_tree:_get_distance_per_gameloop()
	return 0.1 * stonehearth.game_speed:get_game_speed()
end

function Climb_Down_Palm_tree:get_tree_coord(offset)
	local facing = self._mob_tree:get_facing()
	local location = self._mob_tree:get_world_grid_location() + Point3(0,offset.y,0)
	return location + radiant.math.rotate_about_y_axis(Point3.unit_x*offset.x, facing):to_closest_int()
end

function Climb_Down_Palm_tree:run(ai, entity, args)
	self._mob = entity:add_component('mob')
	self._mob_tree = args.resource:add_component('mob')
	self._mob:move_to( self:get_tree_coord(args.path[#args.path]) )
	-- self._mob:turn_to_face_point(self:get_tree_coord({x=0,y=0}))
	for i = #args.path-1, 1, -1 do
		local target_position = self:get_tree_coord(args.path[i])
		local outer_vector = self:_get_vector_to_target(target_position)
		local outer_distance = outer_vector:length()
		self._gameloop_trace = radiant.on_game_loop('climbing down movement', function()
			log:error("_gameloop_trace")
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
		if i%2~=0 then
			effect = "run_climb_ladder_down"
		end
		log:error("before run_effect_timed")
		ai:execute('stonehearth:run_effect_timed', { effect = effect, duration = outer_distance.."m" })
		log:error("after run_effect_timed")
	end
end

function Climb_Down_Palm_tree:stop(ai, entity, args)
	self:_destroy_gameloop_trace()
	local entity_location = radiant.entities.get_world_grid_location(entity)
	local tree_location = radiant.entities.get_world_grid_location(args.resource) or entity_location
	if entity_location.y ~= tree_location.y then
		radiant.entities.move_to(entity, tree_location)
	end
end

return Climb_Down_Palm_tree