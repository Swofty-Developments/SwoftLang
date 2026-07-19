item "crypt_key" {
    skull: "1ae3855f952cd4a03c148a946e3f812a5955ad35cbcb52627ea4acd47d3081"
    name: "<gold>Crypt Key"
    rarity: epic

    tags {
        uses: 3
    }

    on_click(left) {
        set item.tags.uses to (item.tags.uses otherwise 0) - 1
        send "<light_purple>The key turns... (${item.tags.uses otherwise 0} uses left)" to player
    }
}
