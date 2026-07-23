struct Profile { rank: String }

async function build_profile(p: Player) {
    wait 100 millis
    return Profile { rank: "gold" }
}

Player {
    on_join {
        set profile to await spawn build_profile(player)
        send "welcome ${profile.rank}" to player
    }
}
