command "nowplaying" {
    execute {
        set s to song("cafe.nbs")
        set seconds to round(s.length / s.speed)
        send "<gold>${s.title}<gray> by ${s.author} — ${seconds}s" to sender
    }
}
