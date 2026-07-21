// The engine's own PlayerUseItemEvent stays reachable: the curated
// 'PlayerUseItem' identifier wraps the custom-items event (a different
// class), so the class spelling resolves to the generated catalog rows
// (settable item_use_time, cancellable) and canonicalizes to the class
// spelling itself, which the runtime resolves generically.

Player {
    on_use_item {
        send "using ${item} in hand ${hand}" to all
        cancel event
    }
}
