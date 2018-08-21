local FishingAnimations = class()

FishingAnimations.name = 'run fishing animations'
FishingAnimations.does = 'archipelago_biome:fishing_animations'
FishingAnimations.args = {
effort = 'number'
}
FishingAnimations.version = 2
FishingAnimations.priority = 1

function FishingAnimations:start_thinking(ai, entity, args)
	ai:set_think_output({time_waiting_for_fish = args.effort.."m"})
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