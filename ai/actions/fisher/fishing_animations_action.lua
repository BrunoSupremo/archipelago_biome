local FishingAnimations = class()

FishingAnimations.name = 'run fishing animations'
FishingAnimations.does = 'archipelago_biome:fishing_animations'
FishingAnimations.args = {}
FishingAnimations.version = 2
FishingAnimations.priority = 1

function FishingAnimations:start_thinking(ai, entity, args)
	local job_component = entity:get_component('stonehearth:job')
	local level = job_component:get_current_job_level()
	ai:set_think_output({time_waiting_for_fish = 7-level})
end

local ai = stonehearth.ai
return ai:create_compound_action(FishingAnimations)
:execute('stonehearth:run_effect', { effect = "emote_watch_pet" })
:execute('stonehearth:run_effect', { effect = "fishing_start" })
:execute('stonehearth:run_effect', {
	effect = "fishing_middle",
	times = ai.BACK(3).time_waiting_for_fish
	})
:execute('stonehearth:run_effect', { effect = "fishing_end" })