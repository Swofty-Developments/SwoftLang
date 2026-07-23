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

// Future<T> in a type position, `all of` over a typed list. The tick-colored
// (plain) function detaches into an `async { }` task to await the combined
// future; the broadcast then auto-hops back to the tick thread.
function combine_pending(pending: List<Future<Integer>>) {
    set combined to all of pending
    async {
        set results to await combined
        set n to size of results
        broadcast "got ${n} results"
    }
}

Player {
    on_join {
        // fire-and-forget spawn statement (unchanged form)
        spawn build_rank(player)

        // spawn + await: detach a whole async function that awaits inside; its
        // world access (send) auto-hops back to the tick thread
        spawn welcome(player)

        // inline detach: async { } task awaits a spawn value, then the send
        // auto-hops back to the tick thread (replaces `when ... is ready`)
        async {
            set count to await spawn load_stats(player)
            send "loaded ${count}" to player
        }

        // capture a Future in tick context, then await it inside a detached task
        set fut to spawn build_rank(player)
        async {
            set tier to await fut
            send "tier ${tier}" to player
        }

        // async { } statement form stays fire-and-forget
        async {
            wait 20 ticks
            send "async stmt done" to player
        }
    }
}
