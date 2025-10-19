local ArchipelagoBobber = class()

function ArchipelagoBobber:restore()
	radiant.on_game_loop_once('delay to remove bobber stuck/saved', function()
		--in case a bobber was saved before being destroyed,
		--this is the chance to remove it on reloading
		radiant.entities.destroy_entity(self._entity)
	end)
end

return ArchipelagoBobber