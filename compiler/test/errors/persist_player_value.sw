storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

persistent buddy for Player: Player = none
