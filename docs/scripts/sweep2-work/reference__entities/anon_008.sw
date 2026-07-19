command "snippetwrap" {
    execute {
        loop all_entities("SNOWBALL") as leftover {
            remove entity leftover
        }
        send "entities in the world: ${length(all_entities())}" to all
    }
}
