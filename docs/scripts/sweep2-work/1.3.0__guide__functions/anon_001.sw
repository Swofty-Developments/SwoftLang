function double(n: Integer) {
    return n * 2
}

function announce(p: Player, text: String) {
    send "<gold>${text}" to p
}

command "demo" {
    execute {
        send "double(21) = ${double(21)}"
        announce(sender, "functions work")
    }
}
