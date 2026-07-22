item CryptKey { material: "TRIPWIRE_HOOK" tags: { uses: 3 } }

command "use-key" {
    execute {
        set it to custom_item("crypt_key")

        // fallback: absent 'uses' reads as 0
        set left to (it.tags.uses otherwise 0) - 1

        // narrow: only inside the guard is the value known present
        if it.tags.uses exists {
            send "uses left: ${it.tags.uses}" to sender
        }
    }
}
