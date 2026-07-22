command "c" {
    execute {
        set it to custom_item("k")
        set n to it.tags.uses + 1
        send "${n}" to sender
    }
}

item K { material: "STICK" tags: { uses: 3 } }
