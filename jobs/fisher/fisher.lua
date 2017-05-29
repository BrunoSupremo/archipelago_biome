local CraftingJob = require 'stonehearth.jobs.crafting_job'

local FisherClass = class()
radiant.mixin(FisherClass, CraftingJob)

return FisherClass
