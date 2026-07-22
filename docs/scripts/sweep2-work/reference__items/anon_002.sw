item AspectOfTheEnd {
    // id: defaults to "aspect_of_the_end"
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
}

command "sword" {
    execute {
        give item "aspect_of_the_end" to sender      // the id string, not the type name
    }
}
