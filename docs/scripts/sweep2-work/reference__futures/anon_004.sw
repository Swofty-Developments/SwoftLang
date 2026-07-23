struct Profile { rank: String }

async function build_profile(p: Player) {
    wait 100 millis
    return Profile { rank: "gold" }
}

Player {
    on_join {
        when spawn build_profile(player) is ready as profile {
            send "welcome ${profile.rank}" to player
        }
    }
}
