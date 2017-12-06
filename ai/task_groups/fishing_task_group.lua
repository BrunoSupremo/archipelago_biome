local FishingTaskGroup = class()
FishingTaskGroup.name = 'fishing'
FishingTaskGroup.does = 'stonehearth:work'
FishingTaskGroup.priority = {0.40, 0.56}

return stonehearth.ai:create_task_group(FishingTaskGroup)
:work_order_tag("job")
:declare_permanent_task('stonehearth:harvest_resource', { category = "fishing" }, 1.0)
:declare_permanent_task('stonehearth:harvest_renewable_resource', { category = "fishing" }, 0.75)
:declare_permanent_task('archipelago_biome:get_crab', {}, 0.5)
:declare_permanent_task('archipelago_biome:go_fish', {}, 0.25)