mob CryptGhoul {
    type: "ZOMBIE"
    health: 200
}

command "purge" {
    execute {
        loop all_mobs("crypt_ghoul") as g {
            despawn g
        }
        send "custom mobs still alive: ${length(all_mobs())}" to sender
    }
}
