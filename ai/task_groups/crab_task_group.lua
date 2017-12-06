local CrabTaskGroup = class()
CrabTaskGroup.name = 'crab movement'
CrabTaskGroup.does = 'stonehearth:top'
CrabTaskGroup.priority = 1

return stonehearth.ai:create_task_group(CrabTaskGroup)
:declare_task('stonehearth:goto_entity', 1)