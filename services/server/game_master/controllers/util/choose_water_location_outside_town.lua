local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local csg_lib = require 'stonehearth.lib.csg.csg_lib'
local rng = _radiant.math.get_default_rng()
local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3
local Region3 = _radiant.csg.Region3

local MAX_POINTS_TO_CHECK = 700
local MAX_POINTS_TO_TRY_REACHABLE = 200
local MAX_POINTS_TO_CHECK_PER_LOOP = 4

local ChooseWaterLocationOutsideTown = class()

function ChooseWaterLocationOutsideTown:initialize()
   self._log = radiant.log.create_logger('game_master.choose_location_outside_town')
                              :set_prefix('choose loc outside city')
   self._sv.min_range = nil
   self._sv.max_range = nil
   self._sv.target_region = nil
   self._sv.callback = nil
   self._sv.player_id = nil
   self._sv.found_location = false
   self._sv.destroyed = false
   
   self._points_checked = 0
end

--Choose a location outside town to create something
--@param min_range - minimum range from the edge of town
--@param max_range - maximum range from the edge of town
--@param callback - fn to call when we've got the region
--@param target_region - optional, area around the target location to ensure is clear, for placing items
--@param player_id - optional, only consider this player's territory instead of everyone's.
function ChooseWaterLocationOutsideTown:create(min_range, max_range, callback, target_region, player_id)
   if not target_region then
      -- default to a 15x15 area of flatness which fits just inside a world generation feature cell
      local cube = Cube3(Point3.zero):inflated(Point3(7, 0, 7))
      target_region = Region3(cube)
   end

   self._sv.min_range = min_range
   self._sv.max_range = max_range
   self._sv.target_region = target_region
   self._sv.callback  = callback
   self._sv.player_id = player_id
end

function ChooseWaterLocationOutsideTown:activate()
   self._max_y = radiant.terrain.get_terrain_component():get_bounds().max.y

   if not self._sv.found_location and not self._sv.destroyed then
      self._log:debug('On Activate, try to find a location outside town!')
      self:_create_search_thread()
   end
end

function ChooseWaterLocationOutsideTown:destroy()
   self._job = nil
   self._sv.callback = nil -- make sure we no longer have access to callback, since yielded coroutine could return and try to create camp on a destroyed encounter
   self._sv.destroyed = true
   self.__saved_variables:mark_changed()
end

function ChooseWaterLocationOutsideTown:_get_camp_region(location)
   if self._sv.target_region then
      return self._sv.target_region:translated(location)
   else
      -- if the user didn't specify a region, just create a region with a single point in it
      local camp_region = Region3()
      camp_region:add_point(location)
      return camp_region
   end
end

function ChooseWaterLocationOutsideTown:_try_location(location, camp_region)
   if location.y ~= 39 then
      return false
   end

   local test_region

   if camp_region then
      -- Check that there is no terrain above the surface of the region
      if radiant.terrain.intersects_region(camp_region) then
         self._log:debug('location %s intersects terrain. trying again.', location)
         return false
      end

      -- Check that the region is supported by terrain
      local intersection = radiant.terrain.intersect_region(camp_region:translated(-Point3.unit_y))
      if intersection:get_area() ~= camp_region:get_area() then
         self._log:debug('location %s not flat. trying again.', location)
         return false
      end

      test_region = camp_region
   else
      test_region = Region3()
      test_region:add_point(location)
   end

   -- Check that we're not inside a water body
   -- local entities = radiant.terrain.get_entities_in_region(test_region)
   -- for _, entity in pairs(entities) do
   --    local water_component = entity:get_component('stonehearth:water')
   --    if water_component then
   --       return false
   --    end
   -- end

   -- Avoid tunnels
   local test_point = Point3(location)
   test_point.y = self._max_y
   local surface_point = radiant.terrain.get_point_on_terrain(test_point)
   if location ~= surface_point then
      return false
   end

   -- give the callback a shot...
   self._log:debug('About to check if I have a callback!')
   if self._sv.callback then
      self._log:info('Choose location got a callback! Calling it!')
      if not self:_invoke_callback('check_location', location, camp_region) then
         return false
      end
   end

   --if everything is fine, succeed!
   self._log:debug('found location %s', location)
   self:_finalize_location(location, camp_region)

   return true
end

function ChooseWaterLocationOutsideTown:_create_search_thread()
   assert(not self._job)
   -- start a background job to find a location.
   self._job = radiant.create_background_task('choose location outside town', function()
         self:_try_finding_location()
      end)
end

function ChooseWaterLocationOutsideTown:_try_finding_location()
   -- Calculate the region covering the area we want to generate in.
   local territory = self._sv.player_id and stonehearth.terrain:get_territory(self._sv.player_id) or stonehearth.terrain:get_total_territory()
   local territory_region = territory:get_region()
   local valid_points_region = territory_region:inflated(Point2(self._sv.max_range, self._sv.max_range)) - territory_region:inflated(Point2(self._sv.min_range, self._sv.min_range))

   -- Set up a timer to measure our perf.
   local perf_timer = radiant.create_perf_timer()
   perf_timer:start()
   local function stop_timer(perf_timer, result, num_points)
      if perf_timer:is_running() then
         local ms = perf_timer:stop()
         if ms > 200 then
            local error_str = string.format('choose_location_outside_town took %dms to complete. Perimeter points searched: %d. Result: %s', ms, num_points, result)
            self._log:always(error_str)
         end
      end
   end

   if not valid_points_region:empty() then 
      -- Convert the region into a weighted set of cubes to pick from.
      local valid_cubes = WeightedSet(rng)
      for cube in valid_points_region:each_cube() do
         valid_cubes:add(cube, cube:get_area())
      end

      local reachability_check_location
      if self._sv.player_id then
         local town = stonehearth.town:get_town(self._sv.player_id)
         reachability_check_location = radiant.terrain.find_placement_point(town:get_landing_location(), 0, 10)
      else
         local hull = territory:get_convex_hull()
         if hull and #hull > 0 then
            reachability_check_location = radiant.terrain.get_point_on_terrain(Point3(hull[1].x, self._max_y, hull[1].y))
            reachability_check_location.y = reachability_check_location.y + 1  -- The point should be *on top* of the terrain.
         end
      end

      -- Keep choosing random points until we hit a valid one or reach our maximum.
      -- In theory, this is unreliable, but in practice, since we're typically dealing
      -- with 10k+ available points, it's quite robust. We could guarantee a full random
      -- iteration by using an LCG, but that's likely overkill in practice.
      local max_points = math.min(valid_points_region:get_area(), MAX_POINTS_TO_CHECK)
      local point_with_reachable_check_remaining = reachability_check_location and MAX_POINTS_TO_TRY_REACHABLE or 0
      while self._points_checked < max_points do
         self._points_checked = self._points_checked + 1

         local cube = valid_cubes:choose_random()
         local point = radiant.terrain.get_point_on_terrain(Point3(rng:get_int(cube.min.x, cube.max.x), self._max_y, rng:get_int(cube.min.y, cube.max.y)))

         local reachability_check_passed = true
         if point_with_reachable_check_remaining > 0 then
            reachability_check_passed = _radiant.sim.topology.are_strictly_connected(point, reachability_check_location, 0)
            point_with_reachable_check_remaining = point_with_reachable_check_remaining - 1
         end

         if reachability_check_passed then
            local camp_region = self:_get_camp_region(point)
            local found = self:_try_location(point, camp_region)
            if found or self._sv.destroyed then
               stop_timer(perf_timer, 'found a location', self._points_checked)
               self:destroy()
               return
            end

            if self._points_checked % MAX_POINTS_TO_CHECK_PER_LOOP == 0 then
               coroutine.yield()
               if self._sv.destroyed then
                  return
               end
            end
         end
      end
   end

   -- If the loop finished without returning, then we couldn't find a valid point.
   self._log:warning('all convex hull points searched. aborting camp placement.')
   stop_timer(perf_timer, 'aborting. all convex hull points searched.', self._points_checked)
   if self._sv.callback then
      self:_invoke_callback('abort')
   end
   self:destroy()
end

function ChooseWaterLocationOutsideTown:_finalize_location(location, camp_region)
   self._sv.found_location = true
   self.__saved_variables:mark_changed()
   if self._sv.callback then
      self:_invoke_callback('set_location', location, camp_region)
      self._sv.callback = nil
   end
end

function ChooseWaterLocationOutsideTown:_invoke_callback(...)
   if type(self._sv.callback) == 'function' then
      return self._sv.callback(...)
   else
      return radiant.invoke(self._sv.callback, ...)
   end
end

return ChooseWaterLocationOutsideTown