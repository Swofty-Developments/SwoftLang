// The engine's own PlayerUseItemEvent stays reachable: the curated
// 'PlayerUseItem' identifier wraps the custom-items event (a different
// class), so the class spelling resolves to the generated catalog rows
// (settable item_use_time, cancellable) and canonicalizes to the class
// spelling itself, which the runtime resolves generically.

event PlayerUseItemEvent {
    execute {
        set event.item_use_time to 100
        send "using ${event.item_stack} in hand ${event.hand}" to all
        cancel event
    }
}
