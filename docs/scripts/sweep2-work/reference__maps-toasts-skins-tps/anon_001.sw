command "wanted" {
    execute {
        set c to map_canvas()
        draw rect on c from 0, 0 to 127, 127 color "white"
        draw rect on c from 4, 4 to 123, 123 color "black"
        draw text on c at 30, 14 text "WANTED" color "red"
        draw text on c at 12, 60 text sender.name color "black"
        draw pixel on c at 64, 100 color 34
        give map of c to sender
    }
}
