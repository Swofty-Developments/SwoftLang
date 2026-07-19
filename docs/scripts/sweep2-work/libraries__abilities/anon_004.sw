// the single generic surface: every custom-item use flows through here
event PlayerUseItem {
    execute {
        set id to event.custom_id otherwise ""
        // dispatch 'id' to the handlers registered for it (addon internals)
    }
}
