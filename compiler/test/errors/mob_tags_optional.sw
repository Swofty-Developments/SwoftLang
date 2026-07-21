// mob.tags.<path> reads are optional<Any>: using one where a present value is
// required (arithmetic) is an error.
Mob {
    on_spawn() {
        set n to this.tags.level + 1
        broadcast "${n}"
    }
}
