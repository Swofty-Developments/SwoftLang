// A0.1 reverse index: the catalog short name and the simple class name of an
// engine event wrapped by a (possibly renamed) curated event both collapse to
// the SAME typed curated rows, and the handler emits the curated identifier
// the runtime binds by (EventType.fromIdentifier).

// catalog name 'PlayerBlockBreak' -> typed BlockBreak rows, emits "BlockBreak"
event PlayerBlockBreak {
    execute {
        send "broke ${event.block} at ${event.location.block_x}" to event.player
        cancel event
    }
}

// simple class name 'PlayerBlockPlaceEvent' -> typed BlockPlace rows, emits "BlockPlace"
event PlayerBlockPlaceEvent {
    execute {
        send "placed ${event.block}" to event.player
        cancel event
    }
}

// simple class name 'ServerListPingEvent' -> typed ServerPing rows, emits "ServerPing"
event ServerListPingEvent {
    execute {
        set event.motd to "typed motd"
        set event.max to 100
    }
}
