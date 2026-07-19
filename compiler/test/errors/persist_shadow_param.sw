persistent score: Integer = 0

function bump(score: Integer) {
    return score + 1
}

command "bump" {
    execute {
        send "${bump(1)}" to sender
    }
}
