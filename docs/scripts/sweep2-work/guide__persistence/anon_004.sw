persistent spawn: Location = location(0, 100, 0)
persistent warps: Map<String, Location> = new_map()

persistent home for Player: Location = location(0, 64, 0)
persistent last_death for Player: Optional<Location> = none
persistent knockback for Player: Vec = velocity(0, 0.4, 0)
persistent starter for Player: Item = item("stick")
persistent kit for Player: List<Item> = []
persistent waypoints for Player: List<Location> = []
persistent stash for Player: Map<String, Item> = new_map()
