persistent party for Player: List<Player> = []
persistent rival for Player: Optional<Player> = none
persistent duel_partner: Map<String, Player> = new_map()

struct Bout {
    challenger: Player
    opponent: Optional<Player>
    round: Integer = 1
}

persistent bouts: Map<String, Bout> = new_map()
