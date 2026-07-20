block_handler "oak_sign" {
    on_place(player, location, block) {
        send "placed a sign" to player
    }
    on_destroy(location, block) {
        broadcast "a sign broke"
    }
    on_interact(player, location, block) -> Boolean {
        send "you clicked the sign" to player
        return true
    }
    on_touch(entity, location) {
        broadcast "something touched a sign"
    }
    tick(location, block) {
        broadcast "sign tick"
    }
}
