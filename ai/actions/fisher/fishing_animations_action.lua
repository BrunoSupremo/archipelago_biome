local FishingAnimations = class()

FishingAnimations.name = 'run fishing animations'
FishingAnimations.does = 'archipelago_biome:fishing_animations'
FishingAnimations.args = {}
FishingAnimations.version = 2
FishingAnimations.priority = 1

function FishingAnimations:start_thinking(ai, entity, args)
	local job_component = entity:get_component('stonehearth:job')
	local current_loot = job_component:get_curr_job_controller():get_current_loot()
	local effort = current_loot.effort or 60
	ai:set_think_output({time_waiting_for_fish = effort.."m"})
end

local ai = stonehearth.ai
return ai:create_compound_action(FishingAnimations)
:execute('stonehearth:run_effect', { effect = "emote_watch_fish" })
:execute('stonehearth:run_effect', { effect = "fishing_start" })
:execute('stonehearth:run_effect_timed', {
	effect = "fishing_middle",
	duration = ai.BACK(3).time_waiting_for_fish
	})
:execute('stonehearth:run_effect', { effect = "fishing_end" })