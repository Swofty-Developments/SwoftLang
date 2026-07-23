struct Profile { rank: String }

async function build_profile(p: Player) {
    wait 100 millis
    return Profile { rank: "gold" }
}

async function welcome(player: Player) {
    set pending to spawn build_profile(player)   // Future<Profile> — task is running
    send "<gray>Loading your profile..." to player
    set profile to await pending                 // block *this* task until it lands
    send "<lime>Welcome, ${profile.rank}" to player
}
