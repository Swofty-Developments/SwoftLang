// mob.tags.<path> reads are optional<Any>: using one where a present value is
// required (arithmetic) is an error.
event MobSpawn {
    execute {
        set n to event.mob.tags.level + 1
        broadcast "${n}"
    }
}
