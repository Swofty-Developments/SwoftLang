command "meta" {
    execute {
        set s to song("cafe.nbs")
        send "${s.title} by ${s.author}" to sender
    }
}
