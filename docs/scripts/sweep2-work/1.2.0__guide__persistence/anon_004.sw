persistent spawn: Location = location(0, 100, 0)
persistent warps: map<String, Location> = new_map()

persistent home for Player: Location = location(0, 64, 0)
persistent last_death for Player: optional<Location> = none
persistent knockback for Player: Vec = velocity(0, 0.4, 0)
persistent starter for Player: Item = item("stick")
persistent kit for Player: list<Item> = []
persistent waypoints for Player: list<Location> = []
persistent stash for Player: map<String, Item> = new_map()
