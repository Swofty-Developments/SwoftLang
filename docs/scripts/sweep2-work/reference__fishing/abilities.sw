// =========================================================================
// abilities.sw — build the removed ability{} behavior in userland (stdlib
// addon, phase 9 §3; written in SwoftLang)
//
//   import "abilities"
//
//   on_item_use("aspect_of_the_end", "right", with_cooldown(3.0,
//       function(user: Player, held: Item) {
//           send "<green>Whoosh!" to user
//       }))
//
// The language keeps identity, appearance, lore and NBT; gameplay systems
// like "named ability with a cooldown" are a ~50-line userland pattern, not
// a baked-in construct. on_item_use registers a handler dispatched from the
// generic PlayerUseItem event by custom_id and click side; with_cooldown
// wraps any (Player, Item) handler with a per-player cooldown and actionbar
// feedback. Handlers are first-class function values stored in a
// module-level association chain, exactly like the npcs.sw click registry.
// =========================================================================

// association chain: "use:<item_id>:<filter>" -> handler,
// "cd:<slot>:<uuid>" -> ready tick. 'none' means "no entry".
var ability_data = function(lookup: String) return none

// a self-maintained tick clock: 'now' the language does not expose, so the
// addon counts ticks itself for the cooldown windows.
var ability_now = 0

// per-with_cooldown identity so two wrapped handlers never share a window
var ability_seq = 0

function ability_put(key: String, value) {
    set previous to ability_data
    set ability_data to function(lookup: String) {
        if lookup is key return value
        return previous(lookup)
    }
}

function ability_get(key: String) {
    return ability_data(key)
}

function ability_tick() {
    set ability_now to ability_now + 1
}

function ability_clock() {
    return ability_now
}

// advance the cooldown clock once per tick
every 1 ticks {
    ability_tick()
}

// Register a use handler: handler(user: Player, held: Item). filter is one
// of "left", "right", or "any" — kept for API parity with the item on_click
// sugar. The PlayerUseItem event exposes no click side, so every registered
// filter for an item fires here; use the item decl's on_click(<side>) sugar
// when you need true left/right separation. Registering again replaces the
// previous handler for that item id + filter. Pure — safe headless.
export function on_item_use(item_id: String, filter: String, handler) {
    ability_put("use:${item_id}:${filter}", handler)
}

// Wrap a (Player, Item) handler with a per-player cooldown of 'seconds'
// seconds, returning a new handler of the same shape. A gated call sends
// actionbar feedback and does nothing else.
export function with_cooldown(seconds: Double, handler) {
    set ability_seq to ability_seq + 1
    set slot to ability_seq
    return function(user: Player, held: Item) {
        set key to "cd:${slot}:${user.uuid}"
        set ready to ability_get(key) otherwise 0
        if ability_clock() < ready {
            set remaining to (ready - ability_clock()) / 20.0
            actionbar "<red>On cooldown: ${remaining}s" to user
            return 0
        }
        ability_put(key, ability_clock() + round(seconds * 20.0))
        handler(user, held)
        return 0
    }
}

function ability_fire(key: String, user: Player, held: Item) {
    set handler to ability_get(key)
    if handler exists {
        handler(user, held)
    }
}

// dispatch one use to every registered filter for the item; called from the
// event below (module vars reach it through these functions)
function ability_dispatch(user: Player, held: Item, id: String) {
    ability_fire("use:${id}:any", user, held)
    ability_fire("use:${id}:left", user, held)
    ability_fire("use:${id}:right", user, held)
}

// the single generic surface: every custom-item use flows through here
event PlayerUseItem {
    execute {
        set id to event.custom_id otherwise ""
        if id is not "" {
            ability_dispatch(event.player, event.item, id)
        }
    }
}
