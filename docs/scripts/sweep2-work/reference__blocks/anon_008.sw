block_handler "oak_sign" {
    on_place {
        send "placed a sign" to player
    }
    on_destroy {
        broadcast "a sign broke"
    }
    on_interact -> Boolean {
        send "you clicked the sign" to player
        return true
    }
    on_touch {
        broadcast "something touched a sign"
    }
    tick {
        broadcast "sign tick"
    }
}
