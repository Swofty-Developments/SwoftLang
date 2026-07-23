// v1.8.0 futures surface — every form exercised.

async function build_rank(p: Player) {
    wait 1 ticks
    return "MVP"
}

async function load_stats(p: Player) {
    wait 1 ticks
    return 100
}

async function load_friends(p: Player) {
    wait 1 ticks
    return ["alpha", "beta"]
}

// await / spawn-as-value / all of / any of / tuple destructure / async{} expr,
// all inside async context.
async function welcome(p: Player) {
    // spawn <call> as a value -> Future<String>, then await it
    set rankf to spawn build_rank(p)
    set rank to await rankf
    send "welcome ${rank}" to p

    // await spawn <call> directly
    set profile to await spawn build_rank(p)
    send "profile ${profile}" to p

    // positional tuple destructure over a list literal of heterogeneous futures
    set (stats, friends) to await all of [spawn load_stats(p), spawn load_friends(p)]
    set fcount to size of friends
    send "stats ${stats} friends ${fcount}" to p

    // any of -> first result
    set best to await any of [spawn load_stats(p), spawn load_stats(p)]
    send "best ${best}" to p

    // homogeneous all of -> List<T>
    set allstats to await all of [spawn load_stats(p), spawn load_stats(p)]
    set total to size of allstats
    send "count ${total}" to p

    // async { stmts; trailing } as a value -> Future<Integer>
    set computed to async {
        wait 1 ticks
        set x to 21
        x + x
    }
    set doubled to await computed
    send "doubled ${doubled}" to p
}

// Future<T> in a type position, `all of` over a typed list, when-ready in a
// tick-colored (plain) function.
function combine_pending(pending: List<Future<Integer>>) {
    set combined to all of pending
    when combined is ready as results {
        set n to size of results
        broadcast "got ${n} results"
    }
}

Player {
    on_join {
        // fire-and-forget spawn statement (unchanged form)
        spawn build_rank(player)

        // when ... is ready over a spawn value, tick-thread callback
        when spawn load_stats(player) is ready as count {
            send "loaded ${count}" to player
        }

        // capture a Future in tick context, then register a callback on it
        set fut to spawn build_rank(player)
        when fut is ready as tier {
            send "tier ${tier}" to player
        }

        // async { } statement form stays fire-and-forget
        async {
            wait 20 ticks
            send "async stmt done" to player
        }
    }
}
