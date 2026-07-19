// Player-keyed maps: map<Player, V> alongside map<String|Integer, V>. Players
// serialize by uuid on the Java side; the compiler just types the key.

storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

// a persistent Player-keyed map of scalars survives restarts
persistent wins: map<Player, Integer> = new_map()

command "pmap" {
    execute {
        // index-set and builtin form both take a Player key
        set wins at sender to 10
        map_set(wins, sender, 20)

        if map_has(wins, sender) {
            send "tracked" to sender
        }

        // index read yields optional<V>
        set mine to wins[sender] otherwise 0
        send "you have ${mine}" to sender

        // map_keys of a Player-keyed map is list<Player>
        loop map_keys(wins) as p {
            send "player ${p.name}" to sender
        }

        // map foreach binds the Player key and the Integer value
        loop wins as who -> pts {
            send "${who.name}: ${pts}" to sender
        }

        map_delete(wins, sender)
    }
}
