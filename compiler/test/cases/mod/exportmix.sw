// commands and receivers carry no 'export' - they always register when the
// module is imported (they are effects, not symbols)
command "mixcmd" {
    execute {
        send "from the module" to sender
    }
}

Player {
    on_join {
        send "module says hi" to player
    }
}

export item "mix_blade" {
    material: "IRON_SWORD"
    name: "Mix Blade"
}

item "mix_secret" {
    material: "STICK"
    name: "Secret Stick"
}

export function give_blade(target: Player) {
    give item "mix_blade" to target
}
