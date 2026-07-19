// The Entity 'uuid' row composes onto Mob and stays read-only.
event MobSpawn {
    execute {
        set event.mob.uuid to "nope"
    }
}
