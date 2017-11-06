local FishingAnimations = class()

FishingAnimations.name = 'run fishing animations'
FishingAnimations.does = 'archipelago_biome:fishing_animations'
FishingAnimations.args = { }
FishingAnimations.version = 2
FishingAnimations.priority = 1

local ai = stonehearth.ai
return ai:create_compound_action(FishingAnimations)
			:execute('stonehearth:run_effect', { effect = "emote_watch_pet" })
			:execute('stonehearth:run_effect', { effect = "fishing_start" })
			:execute('stonehearth:run_effect', {
				effect = "hoe",
				times = "2"
				})
			:execute('stonehearth:run_effect', { effect = "work" })