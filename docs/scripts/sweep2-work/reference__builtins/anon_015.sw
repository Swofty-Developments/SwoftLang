command "colors" {
    execute {
        send strip_color("&aGreen &lBold") to sender          // Green Bold
        send legacy_to_mini("&aGreen") to sender
        send gradient("Rainbow road", "#ff0000", "#0000ff") to sender
        send rainbow("Party time") to sender
    }
}
