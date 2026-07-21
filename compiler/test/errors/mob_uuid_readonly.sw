// The Entity 'uuid' row composes onto Mob and stays read-only.
Mob {
    on_spawn() {
        set this.uuid to "nope"
    }
}
