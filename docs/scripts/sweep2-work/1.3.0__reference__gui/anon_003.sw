gui "spec" {
    rows: 1
    title: "Spec"
    state { enabled: true }

    slot 0 {
        item {
            material: "DIAMOND"                      // XOR skull
            name: "<green>Toggle"
            lore: ["<gray>line 1", "<gray>${player.name}"]
            amount: 1
            glint: state.enabled
        }
    }
    slot 1 {
        item {
            skull: player.name                       // player head
            name: "<aqua>You"
        }
    }
}
