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
        // the 'set m at k to v' natural form takes a Player key
        set wins at sender to 10
        set wins at sender to 20

        if wins has sender {
            send "tracked" to sender
        }

        // index read yields optional<V>
        set mine to wins[sender] otherwise 0
        send "you have ${mine}" to sender

        // 'keys of m' of a Player-keyed map is list<Player>
        loop keys of wins as p {
            send "player ${p.name}" to sender
        }

        // map foreach binds the Player key and the Integer value
        loop wins as who -> pts {
            send "${who.name}: ${pts}" to sender
        }

        delete wins at sender
    }
}
