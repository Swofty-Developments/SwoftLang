function inspect(x: Either<Mob|String>) {
    if x is a Entity {
        // the typed Mob rows and the shared Entity rows both apply here
        send "mob ${x.name} (${x.type})" to all
    } else {
        send "not an entity: ${x}" to all
    }
}
