export function greet(target: Player) {
    send "<green>hello from a library" to target
}

export async function delayed_greet(target: Player) {
    wait 1 seconds
    greet(target)
}

function internal_detail() return 42     // invisible to importers
