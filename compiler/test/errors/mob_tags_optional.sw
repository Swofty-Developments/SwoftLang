// mob.tags.<path> reads are Optional<Any>: using one where a present value is
// required (arithmetic) is an error.
Mob {
    on_spawn {
        set n to mob.tags.level + 1
        broadcast "${n}"
    }
}
