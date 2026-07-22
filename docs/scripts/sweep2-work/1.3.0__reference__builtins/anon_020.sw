command "blank-map" {
    execute {
        set c to map_canvas()
        draw rect on c from 0, 0 to 127, 127 color "white"
        give map of c to sender
    }
}
