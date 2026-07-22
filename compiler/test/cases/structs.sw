struct Point {
    x: Integer
    y: Integer = 0
}

struct Guild {
    name: String
    level: Integer = 1
    members: list<Player>
    bank: map<String, Integer>
    home: optional<Location>
    hq: Point
}

persistent guild for Player: Guild = Guild { name: "", members: [], bank: new_map(), home: none, hq: Point { x: 0 } }

function level_up(g: Guild) {
    set g.level to g.level + 1
}

command "guilds" {
    execute {
        set g to Guild { name: "Knights", members: [sender], bank: new_map(), home: none, hq: Point { x: 5, y: 5 } }
        send "${g.name} lvl ${g.level}" to sender
        set g.level to g.level + 1
        set g.bank at "gold" to 100
        add sender to g.members
        set g.home to location_of(sender)
        set g.hq.x to 10
        send "hq at ${g.hq.x}, ${g.hq.y}" to sender
        set snap to g.copy()
        level_up(g)
        send "level is now ${g.level}, snapshot ${snap.level}" to sender
        set guild for sender to g
        set gd to guild for sender
        send "stored ${gd.name}" to sender
    }
}
