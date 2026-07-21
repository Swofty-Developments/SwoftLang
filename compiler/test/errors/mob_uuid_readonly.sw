// The Entity 'uuid' row composes onto Mob and stays read-only.
Mob {
    on_spawn {
        set mob.uuid to "nope"
    }
}
