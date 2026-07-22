// the single generic surface: every custom-item use flows through here
Item {
    on_use(player) {
        set id to custom_id(this) otherwise ""
        // dispatch 'id' to the handlers registered for it (addon internals)
    }
}
