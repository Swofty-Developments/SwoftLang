mob CryptGhoul {
    // id: defaults to "crypt_ghoul"
    type: "ZOMBIE"
    health: 40
}

command "count-ghouls" {
    execute {
        set n to 0
        loop all_mobs() as m {
            if m is a CryptGhoul {       // narrows m to CryptGhoul in the block
                set n to n + 1
            }
        }
        send "<gray>${n} crypt ghouls abroad" to sender
    }
}
